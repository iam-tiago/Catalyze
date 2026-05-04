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
                        CatalystCard {
                            VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                                CatalystCardHeader("AI Response", icon: "sparkles") {
                                    if isGenerating {
                                        CatalystLoadingIndicator()
                                    }
                                }
                                
                                MarkdownText(markdown: streamingText)
                                    .font(CatalystTypography.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
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
                    CatalystCard {
                        VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                            CatalystCardHeader("AI Response", icon: "sparkles") {
                                if isGenerating {
                                    CatalystLoadingIndicator()
                                }
                            }
                            
                            MarkdownText(markdown: streamingText)
                                .font(CatalystTypography.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(CatalystSpacing.xl)
        }
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
