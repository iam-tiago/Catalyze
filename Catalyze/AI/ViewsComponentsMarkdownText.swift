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
        // Pre-process markdown to fix spacing issues
        let processedMarkdown = preprocessMarkdown(markdown)
        
        if let attributedString = try? AttributedString(
            markdown: processedMarkdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) {
            Text(attributedString)
                .textSelection(.enabled)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            // Fallback if markdown parsing fails
            Text(processedMarkdown)
                .textSelection(.enabled)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// Pre-processes markdown to ensure proper spacing around bold text and other elements
    private func preprocessMarkdown(_ text: String) -> String {
        var processed = text
        
        // 1. Ensure space after period before capital letter if not already present
        // "plan.The" -> "plan. The"
        processed = processed.replacingOccurrences(
            of: #"\.([A-Z])"#,
            with: ". $1",
            options: .regularExpression
        )
        
        // 2. Ensure space after colon before capital letter
        // "Skills:Both" -> "Skills: Both"
        processed = processed.replacingOccurrences(
            of: #":([A-Z])"#,
            with: ": $1",
            options: .regularExpression
        )
        
        // 3. Add newline before bold text that appears after any word character
        // "word**Bold**" -> "word\n\n**Bold**"
        processed = processed.replacingOccurrences(
            of: #"([a-zA-Z0-9.,;:!?)\-—])(\*\*[A-Z])"#,
            with: "$1\n\n$2",
            options: .regularExpression
        )
        
        // 4. Add space after closing bold if followed immediately by capital letter
        // "**text**Next" -> "**text** Next"
        processed = processed.replacingOccurrences(
            of: #"(\*\*)([A-Z][a-z])"#,
            with: "$1 $2",
            options: .regularExpression
        )
        
        // 5. Fix em-dashes without spaces around bold text
        // "text.—" -> "text.\n\n—"
        processed = processed.replacingOccurrences(
            of: #"\.—"#,
            with: ".\n\n—",
            options: .regularExpression
        )
        
        // 6. Add extra newline before headers for better separation (if not at start)
        processed = processed.replacingOccurrences(
            of: #"\n(#{1,6} )"#,
            with: "\n\n$1",
            options: .regularExpression
        )
        
        // 7. Clean up multiple consecutive newlines (max 2)
        processed = processed.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )
        
        return processed
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            // Test case 1: From screenshot - colons and em-dashes
            MarkdownText(markdown: """
## Mariana Canabarro — Coaching Analysis

### Key Patterns

**Early-career foundation building:**Mariana's strengths cluster around mindset and interpersonal skills (Growth Mindset, Emotional Intelligence) rather than purely technical ones — a strong base for long-term growth, but technical depth needs deliberate acceleration.**Emerging technical skills need reinforcement:**Both Code Quality and Debugging are at the Emerging level, suggesting she can produce reasonable code but still struggles when things break or complexity increases — a common T1-3 bottleneck.**Adaptability gap may compound other challenges:**At early career stages, low adaptability can slow down learning velocity, especially when debugging requires shifting mental models quickly.

### Coaching Recommendations

**Pair debugging sessions explicitly:**Assign Mariana a structured debugging exercise weekly (real bugs or simulated ones). Debrief together — focus on process (hypothesis → test → learn), not just the fix. This directly targets her two technical growth areas simultaneously.**Leverage her Growth Mindset actively:**Give her stretch tasks slightly outside her comfort zone with a clear safety net. Her mindset strength means she'll lean in — but she needs the EM to name the learning goal upfront so she stays oriented.**Build adaptability through low-stakes change exposure:**Rotate her across small, varied tasks or codebases. Debrief after context switches: "What felt hard about switching? What helped?" — building metacognition around adaptability.

### Watch-outs

**No recent observations recorded** — this is a risk in itself. Without data, coaching risks being based on stale signals. Prioritize more frequent 1:1 check-ins and note concrete behavioral evidence.**EQ without assertiveness:**High emotional intelligence at T1-3 can sometimes mask hesitation to push back or ask for help — watch for over-accommodation or silent struggles.
""")
            .padding()
            
            Divider()
            
            // Test case 2: Original example
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
            
            Divider()
            
            // Test case 3: Mixed content with lists and formatting
            MarkdownText(markdown: """
## Team Strengths

The team demonstrates several key capabilities:

- **Technical Excellence**: All members show strong coding skills
- **Collaboration**: Regular pair programming sessions
- **Ownership**: Clear accountability for deliverables

### Areas for Growth

1. Documentation practices need improvement
2. Cross-team communication could be better
3. Testing coverage is inconsistent

**Next Steps:**Schedule a retrospective to discuss these patterns. Focus on quick wins in documentation.

## Long-term Strategy

Building sustainable practices requires commitment.**Documentation First:**Make it a prerequisite for PR approval.**Testing Culture:**Aim for 80% coverage minimum.
""")
            .padding()
        }
    }
}
