//
//  SettingsView.swift
//  Catalyze
//
//  Settings view for configuring the EM profile, API credentials, and
//  app preferences. Also includes import/export functionality.
//
//  Equivalent to `src/components/Settings/SettingsView.tsx` in the web app.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var role = ""
    @State private var teamName = ""
    @State private var photoUrl = ""
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var showingTestResult = false
    @State private var testResultMessage = ""
    @State private var isTestingConnection = false

    var body: some View {
        Form {
            // EM Profile section
            Section("Your Profile") {
                TextField("Name", text: $name)
                    .textContentType(.name)

                TextField("Role", text: $role)
                    .textContentType(.jobTitle)

                TextField("Team Name (optional)", text: $teamName)

                TextField("Photo URL (optional)", text: $photoUrl)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 60, height: 60)
                    }
                }

                Button("Save Profile") {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
            }

            // API Credentials section
            Section {
                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                TextField("Base URL", text: $baseURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button {
                    Task { await testConnection() }
                } label: {
                    if isTestingConnection {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Testing...")
                        }
                    } else {
                        Label("Test Connection", systemImage: "network")
                    }
                }
                .disabled(apiKey.isEmpty || isTestingConnection)

                if showingTestResult {
                    Text(testResultMessage)
                        .font(.caption)
                        .foregroundStyle(testResultMessage.contains("✓") ? .green : .red)
                }

                Button("Save Credentials") {
                    saveCredentials()
                }
                .buttonStyle(.borderedProminent)
            } header: {
                Text("API Credentials")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter your Anthropic API key or a LiteLLM-compatible proxy endpoint.")
                    Text("Default: \(ClaudeClient.defaultBaseURL)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Data Management section
            Section("Data Management") {
                Button {
                    // Export functionality (placeholder)
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                Button {
                    // Import functionality (placeholder)
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            }

            // About section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
        }
    }

    // MARK: - Helpers --------------------------------------------------------

    private func loadSettings() {
        // Load EM profile
        name = store.emProfile.name
        role = store.emProfile.role
        teamName = store.emProfile.teamName ?? ""
        photoUrl = store.emProfile.photoUrl ?? ""

        // Load API credentials
        apiKey = store.apiKey
        baseURL = store.baseURL
    }

    private func saveProfile() {
        let profile = EMProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            role: role.trimmingCharacters(in: .whitespaces),
            teamName: teamName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : teamName.trimmingCharacters(in: .whitespaces),
            photoUrl: photoUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : photoUrl.trimmingCharacters(in: .whitespaces)
        )
        store.setEMProfile(profile)
    }

    private func saveCredentials() {
        store.setApiKey(apiKey.trimmingCharacters(in: .whitespaces))
        store.setBaseURL(baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            ? ClaudeClient.defaultBaseURL
            : baseURL.trimmingCharacters(in: .whitespaces))
    }

    private func testConnection() async {
        isTestingConnection = true
        showingTestResult = false

        let client = ClaudeClient(
            apiKey: apiKey.trimmingCharacters(in: .whitespaces),
            baseURL: baseURL.trimmingCharacters(in: .whitespaces).isEmpty
                ? ClaudeClient.defaultBaseURL
                : baseURL.trimmingCharacters(in: .whitespaces)
        )

        do {
            _ = try await client.complete(
                messages: [ChatMessage(role: "user", content: "Hello")],
                maxTokens: 10
            ) { _ in }

            testResultMessage = "✓ Connection successful"
            showingTestResult = true
        } catch {
            testResultMessage = "✗ Connection failed: \(error.localizedDescription)"
            showingTestResult = true
        }

        isTestingConnection = false
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppStore())
            .modelContainer(try! PersistenceController.makePreviewContainer())
    }
}
