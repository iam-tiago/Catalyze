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
        if let attributedString = try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributedString)
                .textSelection(.enabled)
        } else {
            // Fallback if markdown parsing fails
            Text(markdown)
                .textSelection(.enabled)
        }
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
