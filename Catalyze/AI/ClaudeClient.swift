//
//  ClaudeClient.swift
//  Catalyze
//
//  Streaming client for the Anthropic Messages API. Equivalent to
//  `src/lib/claude.ts` from the web app.
//
//  Why hand-rolled instead of using a third-party SDK:
//  - The Anthropic streaming format is Server-Sent Events with a small,
//    well-documented set of event types. URLSession.bytes(for:) handles
//    SSE parsing nicely with a few lines of code.
//  - No external dependency = smaller binary, no Swift Package surprises
//    during App Store review.
//  - Mirrors the web app's callback shape exactly:
//      onChunk(accumulatedTextSoFar)  // not the delta
//
//  Auth:
//  - The user enters their API key in Settings (stored in Keychain).
//  - Anthropic's direct API expects the `x-api-key` and `anthropic-version`
//    headers. Proxies (LiteLLM/HAI) typically use `Authorization: Bearer ...`
//    — we send both, which is harmless when one is ignored.
//

import Foundation

// MARK: - Errors -------------------------------------------------------------

enum ClaudeError: LocalizedError {
    case missingApiKey
    case badResponse(status: Int, body: String)
    case decoding(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "No API key configured. Set one in Settings."
        case .badResponse(let status, let body):
            return "Claude API error \(status): \(body)"
        case .decoding(let msg):
            return "Failed to decode Claude response: \(msg)"
        case .cancelled:
            return "Request cancelled."
        }
    }
}

// MARK: - Client -------------------------------------------------------------

struct ClaudeClient {

    // The web app's defaults.
    static let defaultBaseURL = "https://api.anthropic.com/v1"
    static let defaultModel   = "claude-sonnet-4-6"
    static let proxyModel     = "anthropic--claude-4.5-sonnet"

    let apiKey: String
    let baseURL: String

    init(apiKey: String, baseURL: String = ClaudeClient.defaultBaseURL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    /// Resolve which model identifier to use based on the base URL —
    /// matches the logic in `lib/claude.ts`.
    var resolvedModel: String {
        baseURL.contains("anthropic.com") ? Self.defaultModel : Self.proxyModel
    }

    // MARK: Public API -------------------------------------------------------

    /// Send a message to Claude with streaming. The callback receives the
    /// running accumulated text on each chunk (not just the delta), to
    /// match the web app's contract. Returns the final accumulated text.
    @discardableResult
    func complete(
        system: String? = nil,
        messages: [ChatMessage],
        maxTokens: Int = 1024,
        onChunk: @escaping @Sendable (String) -> Void
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw ClaudeError.missingApiKey }

        let url = URL(string: "\(baseURL)/messages")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        let payload = MessagesRequest(
            model: resolvedModel,
            maxTokens: maxTokens,
            stream: true,
            system: system,
            messages: messages
        )
        req.httpBody = try JSONEncoder().encode(payload)

        let (bytes, response) = try await URLSession.shared.bytes(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.badResponse(status: -1, body: "no HTTP response")
        }

        if !(200..<300).contains(http.statusCode) {
            // Drain the body for a useful error message.
            var body = ""
            for try await line in bytes.lines { body += line + "\n" }
            throw ClaudeError.badResponse(status: http.statusCode, body: body)
        }

        // SSE parsing: the spec says events are separated by blank lines
        // and `data:` lines carry JSON payloads. URLSession's `.lines`
        // already splits on \n which is good enough here — Anthropic's
        // streaming format puts one JSON object per `data:` line.
        var accumulated = ""

        for try await rawLine in bytes.lines {
            try Task.checkCancellation()

            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("data:") else { continue }
            let jsonStr = String(line.dropFirst("data:".count))
                .trimmingCharacters(in: .whitespaces)
            if jsonStr.isEmpty || jsonStr == "[DONE]" { continue }

            guard let data = jsonStr.data(using: .utf8) else { continue }

            // We only care about `content_block_delta` events; the rest
            // (message_start, ping, message_stop) carry no text we need.
            if let event = try? JSONDecoder().decode(SSEEvent.self, from: data),
               event.type == "content_block_delta",
               let text = event.delta?.text
            {
                accumulated += text
                onChunk(accumulated)
            }
        }

        return accumulated
    }
}

// MARK: - Request / response wire types --------------------------------------

struct ChatMessage: Codable, Hashable {
    let role: String   // "user" | "assistant"
    let content: String
}

private struct MessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let stream: Bool
    let system: String?
    let messages: [ChatMessage]

    enum CodingKeys: String, CodingKey {
        case model, stream, system, messages
        case maxTokens = "max_tokens"
    }
}

private struct SSEEvent: Decodable {
    let type: String
    let delta: Delta?

    struct Delta: Decodable {
        let type: String?
        let text: String?
    }
}
