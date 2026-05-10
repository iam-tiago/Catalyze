//
//  MarkdownText.swift
//  Catalyze
//
//  A SwiftUI view that renders markdown text with proper formatting.
//  Handles the AI-generated insights that come with markdown syntax.
//

import SwiftUI

struct MarkdownText: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let attributedString = try? AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .full,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )
            ) {
                // Split by double newlines to create visual separation between sections
                let sections = markdown.components(separatedBy: "\n\n")
                
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    if !section.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if let sectionAttributed = try? AttributedString(
                            markdown: section,
                            options: AttributedString.MarkdownParsingOptions(
                                interpretedSyntax: .full,
                                failurePolicy: .returnPartiallyParsedIfPossible
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sectionAttributed)
                                    .textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(4)
                                
                                // Add extra spacing after headers and major sections
                                if section.hasPrefix("#") || section.hasPrefix("**") {
                                    Spacer()
                                        .frame(height: 4)
                                }
                            }
                            .padding(.bottom, isListItem(section) ? 4 : 8)
                        }
                    }
                }
            } else {
                // Fallback if markdown parsing fails
                Text(markdown)
                    .textSelection(.enabled)
                    .lineSpacing(4)
            }
        }
    }
    
    private func isListItem(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("-") || trimmed.hasPrefix("•") || 
               trimmed.hasPrefix("*") || trimmed.range(of: #"^\d+\."#, options: .regularExpression) != nil
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            MarkdownText(markdown: """
## Individual Analysis for Alice Chen

### Strengths
- **Code Quality**: Demonstrates strong attention to detail
- *SwiftUI Expertise*: Leading the migration effort

### Growth Areas
1. Public speaking
2. Presenting to stakeholders
3. Conference talks

**Recommendation**: Consider a mentorship program focused on communication skills.
""")
            .padding()
        }
    }
}
