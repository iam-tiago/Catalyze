//
//  CatalystButton.swift
//  Catalyze
//
//  Reusable button components with consistent styling and loading states.
//  Provides primary, secondary, and specialized button styles.
//

import SwiftUI

// MARK: - Primary Action Button ----------------------------------------------

struct CatalystPrimaryButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                HStack(spacing: CatalystSpacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    Text(loadingText)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Label(title, systemImage: icon)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!isEnabled || isLoading)
    }
    
    private var loadingText: String {
        if title.contains("Generate") {
            return "Generating..."
        } else if title.contains("Analyze") {
            return "Analyzing..."
        } else if title.contains("Prepare") {
            return "Preparing..."
        } else {
            return "Loading..."
        }
    }
}

// MARK: - Field Label --------------------------------------------------------

struct CatalystFieldLabel: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(CatalystTypography.label)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Error Banner -------------------------------------------------------

struct CatalystErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: CatalystSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(message)
                .font(CatalystTypography.body)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(CatalystSpacing.lg)
        .background(
            .red.opacity(CatalystOpacity.light),
            in: RoundedRectangle(cornerRadius: CatalystRadius.sm)
        )
    }
}

// MARK: - Loading Indicator --------------------------------------------------

struct CatalystLoadingIndicator: View {
    let text: String
    
    init(_ text: String = "Streaming...") {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: CatalystSpacing.sm) {
            ProgressView()
                .controlSize(.small)
            Text(text)
                .font(CatalystTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Buttons & Components") {
    ScrollView {
        VStack(spacing: CatalystSpacing.xl) {
            // Buttons
            CatalystCard {
                VStack(spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("Buttons", icon: "square.and.arrow.up.fill")
                    
                    CatalystPrimaryButton(
                        "Generate AI Insight",
                        icon: "sparkles",
                        action: { print("Generate") }
                    )
                    
                    CatalystPrimaryButton(
                        "Generate AI Insight",
                        icon: "sparkles",
                        isLoading: true,
                        action: { }
                    )
                    
                    CatalystPrimaryButton(
                        "Disabled Button",
                        icon: "xmark.circle",
                        isEnabled: false,
                        action: { }
                    )
                }
            }
            
            // Field Labels
            CatalystCard {
                VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("Form Elements", icon: "list.bullet.clipboard")
                    
                    VStack(alignment: .leading, spacing: CatalystSpacing.sm) {
                        CatalystFieldLabel("Team Member")
                        
                        Text("This is where a picker would go")
                            .font(CatalystTypography.body)
                            .foregroundStyle(.secondary)
                            .padding(CatalystSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                .quaternary.opacity(CatalystOpacity.strong),
                                in: RoundedRectangle(cornerRadius: CatalystRadius.sm)
                            )
                    }
                }
            }
            
            // Error Banner
            CatalystCard {
                VStack(spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("Error States", icon: "exclamationmark.triangle")
                    
                    CatalystErrorBanner(message: "Failed to generate insight. Please check your API key and try again.")
                }
            }
            
            // Loading Indicator
            CatalystCard {
                VStack(spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("Loading States", icon: "arrow.triangle.2.circlepath")
                    
                    HStack {
                        Text("AI Response")
                            .font(CatalystTypography.cardTitle)
                        
                        Spacer()
                        
                        CatalystLoadingIndicator()
                    }
                }
            }
        }
        .padding(CatalystSpacing.xl)
    }
}
