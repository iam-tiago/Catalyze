//
//  CatalystInsightLayout.swift
//  Catalyze
//
//  A specialized layout component for Insights tabs.
//  Provides consistent input/output pattern with streaming response support.
//

import SwiftUI

// MARK: - Insight Tab Layout -------------------------------------------------

struct CatalystInsightLayout<InputContent: View>: View {
    let inputTitle: String
    let inputIcon: String
    let inputContent: InputContent
    let streamingText: String
    let isGenerating: Bool
    let errorMessage: String?
    
    init(
        inputTitle: String,
        inputIcon: String = "brain.fill",
        streamingText: String,
        isGenerating: Bool,
        errorMessage: String? = nil,
        @ViewBuilder inputContent: () -> InputContent
    ) {
        self.inputTitle = inputTitle
        self.inputIcon = inputIcon
        self.streamingText = streamingText
        self.isGenerating = isGenerating
        self.errorMessage = errorMessage
        self.inputContent = inputContent()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: CatalystSpacing.xl) {
                    // Input Card
                    CatalystCard {
                        VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                            CatalystCardHeader(inputTitle, icon: inputIcon)
                            
                            inputContent
                            
                            if let error = errorMessage {
                                CatalystErrorBanner(message: error)
                            }
                        }
                    }
                    
                    // Output Card
                    if !streamingText.isEmpty {
                        AIOutputCard(text: streamingText, isGenerating: isGenerating)
                    }
                }
                .padding(CatalystSpacing.xl)
                .frame(minWidth: geometry.size.width)
            }
        }
    }
}

// MARK: - Simple Insight Layout (no geometry reader) ------------------------

struct CatalystSimpleInsightLayout<InputContent: View>: View {
    let inputTitle: String
    let inputIcon: String
    let inputContent: InputContent
    let streamingText: String
    let isGenerating: Bool
    let errorMessage: String?
    
    init(
        inputTitle: String,
        inputIcon: String = "brain.fill",
        streamingText: String,
        isGenerating: Bool,
        errorMessage: String? = nil,
        @ViewBuilder inputContent: () -> InputContent
    ) {
        self.inputTitle = inputTitle
        self.inputIcon = inputIcon
        self.streamingText = streamingText
        self.isGenerating = isGenerating
        self.errorMessage = errorMessage
        self.inputContent = inputContent()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: CatalystSpacing.xl) {
                // Input Card
                CatalystCard {
                    VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                        CatalystCardHeader(inputTitle, icon: inputIcon)
                        
                        inputContent
                        
                        if let error = errorMessage {
                            CatalystErrorBanner(message: error)
                        }
                    }
                }
                
                // Output Card
                if !streamingText.isEmpty {
                    AIOutputCard(text: streamingText, isGenerating: isGenerating)
                }
            }
            .padding(CatalystSpacing.xl)
        }
    }
}

// MARK: - AI Output Card -----------------------------------------------------

struct AIOutputCard: View {
    let text: String
    let isGenerating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
            // Header
            HStack(spacing: CatalystSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.357, green: 0.357, blue: 0.839).opacity(0.22))
                        .shadow(color: Color(red: 0.357, green: 0.357, blue: 0.839).opacity(0.45), radius: 10, x: 0, y: 0)
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.588, green: 0.588, blue: 0.925))
                }
                .frame(width: 30, height: 30)

                Text("AI Insight")
                    .font(CatalystTypography.sectionTitle)
                    .foregroundStyle(.white)

                Spacer()

                if isGenerating {
                    ProgressView()
                        .tint(.white.opacity(0.55))
                        .controlSize(.small)
                }
            }

            Rectangle()
                .fill(.white.opacity(0.10))
                .frame(height: 0.5)

            MarkdownText(markdown: text)
                .font(CatalystTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .colorScheme(.dark)
        }
        .padding(CatalystSpacing.xl)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                MeshGradient(width: 2, height: 2, points: [
                    [0, 0], [1, 0],
                    [0, 1], [1, 1]
                ], colors: [
                    Color(red: 0.176, green: 0.106, blue: 0.412),
                    Color(red: 0.102, green: 0.039, blue: 0.180),
                    Color(red: 0.118, green: 0.106, blue: 0.294),
                    Color(red: 0.059, green: 0.043, blue: 0.165)
                ])

                Canvas { ctx, size in
                    let spacing: CGFloat = 22
                    let radius: CGFloat = 0.85
                    var x = spacing / 2
                    while x < size.width {
                        var y = spacing / 2
                        while y < size.height {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                                with: .color(.white)
                            )
                            y += spacing
                        }
                        x += spacing
                    }
                }
                .opacity(0.05)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CatalystRadius.lg))
        .shadow(color: Color(red: 0.176, green: 0.106, blue: 0.412).opacity(0.35), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Insight Layout") {
    CatalystSimpleInsightLayout(
        inputTitle: "Generate Insight",
        streamingText: "## Sample Response\n\nThis is a **sample** AI response with *markdown* formatting.\n\n- Point 1\n- Point 2\n- Point 3",
        isGenerating: true,
        errorMessage: nil
    ) {
        VStack(spacing: CatalystSpacing.lg) {
            VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                CatalystFieldLabel("Team Member")
                
                Text("Selected: Alice Chen")
                    .font(CatalystTypography.body)
            }
            
            CatalystPrimaryButton(
                "Generate AI Insight",
                icon: "sparkles",
                isLoading: true,
                action: { }
            )
        }
    }
}

#Preview("With Error") {
    CatalystSimpleInsightLayout(
        inputTitle: "Generate Insight",
        streamingText: "",
        isGenerating: false,
        errorMessage: "Failed to connect to Claude API. Please check your settings."
    ) {
        VStack(spacing: CatalystSpacing.lg) {
            VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                CatalystFieldLabel("Team Member")
                
                Text("Choose a member...")
                    .font(CatalystTypography.body)
                    .foregroundStyle(.secondary)
            }
            
            CatalystPrimaryButton(
                "Generate AI Insight",
                icon: "sparkles",
                isEnabled: false,
                action: { }
            )
        }
    }
}
