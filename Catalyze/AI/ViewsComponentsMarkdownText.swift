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
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdownBlocks(markdown), id: \.id) { block in
                renderBlock(block)
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block.type {
        case .heading1:
            Text(block.content)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
        case .heading2:
            Text(block.content)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 6)
                .padding(.bottom, 3)
            
        case .heading3:
            Text(block.content)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 4)
                .padding(.bottom, 2)
            
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .fontWeight(.bold)
                renderInlineFormatting(block.content)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 12)
            
        case .numberedListItem:
            HStack(alignment: .top, spacing: 8) {
                Text("\(block.listIndex ?? 1).")
                    .fontWeight(.semibold)
                renderInlineFormatting(block.content)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 12)
            
        case .paragraph:
            renderInlineFormatting(block.content)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }
    
    /// Renders inline formatting (bold, italic) within a text block
    private func renderInlineFormatting(_ text: String) -> Text {
        // Parse inline markdown
        let segments = parseInlineMarkdown(text)
        
        var result = Text("")
        for segment in segments {
            var segmentText = Text(segment.text)
            
            if segment.isBold {
                segmentText = segmentText.fontWeight(.bold)
            }
            if segment.isItalic {
                segmentText = segmentText.italic()
            }
            
            result = result + segmentText
        }
        
        return result
    }
    
    /// Parses markdown into blocks (headers, paragraphs, list items)
    private func parseMarkdownBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentParagraph: [String] = []
        var listCounter = 1
        var previousWasList = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmed.isEmpty {
                // Flush current paragraph if any
                if !currentParagraph.isEmpty {
                    blocks.append(MarkdownBlock(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " ")
                    ))
                    currentParagraph = []
                }
                previousWasList = false
                listCounter = 1
                continue
            }
            
            // Check for headers
            if trimmed.hasPrefix("### ") {
                // Flush current paragraph
                if !currentParagraph.isEmpty {
                    blocks.append(MarkdownBlock(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " ")
                    ))
                    currentParagraph = []
                }
                blocks.append(MarkdownBlock(
                    type: .heading3,
                    content: String(trimmed.dropFirst(4))
                ))
                previousWasList = false
                continue
            } else if trimmed.hasPrefix("## ") {
                // Flush current paragraph
                if !currentParagraph.isEmpty {
                    blocks.append(MarkdownBlock(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " ")
                    ))
                    currentParagraph = []
                }
                blocks.append(MarkdownBlock(
                    type: .heading2,
                    content: String(trimmed.dropFirst(3))
                ))
                previousWasList = false
                continue
            } else if trimmed.hasPrefix("# ") {
                // Flush current paragraph
                if !currentParagraph.isEmpty {
                    blocks.append(MarkdownBlock(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " ")
                    ))
                    currentParagraph = []
                }
                blocks.append(MarkdownBlock(
                    type: .heading1,
                    content: String(trimmed.dropFirst(2))
                ))
                previousWasList = false
                continue
            }
            
            // Check for unordered list items (-, *, •)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                // Flush current paragraph
                if !currentParagraph.isEmpty {
                    blocks.append(MarkdownBlock(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " ")
                    ))
                    currentParagraph = []
                }
                blocks.append(MarkdownBlock(
                    type: .listItem,
                    content: String(trimmed.dropFirst(2))
                ))
                previousWasList = true
                continue
            }
            
            // Check for numbered list items (1., 2., etc.)
            if let match = trimmed.firstMatch(of: /^(\d+)\.\s+(.+)/) {
                // Flush current paragraph
                if !currentParagraph.isEmpty {
                    blocks.append(MarkdownBlock(
                        type: .paragraph,
                        content: currentParagraph.joined(separator: " ")
                    ))
                    currentParagraph = []
                }
                
                if !previousWasList {
                    listCounter = 1
                }
                
                blocks.append(MarkdownBlock(
                    type: .numberedListItem,
                    content: String(match.2),
                    listIndex: listCounter
                ))
                listCounter += 1
                previousWasList = true
                continue
            }
            
            // Regular paragraph line - accumulate
            if !previousWasList {
                currentParagraph.append(trimmed)
            } else {
                // Start new paragraph after list
                currentParagraph = [trimmed]
                previousWasList = false
            }
        }
        
        // Flush any remaining paragraph
        if !currentParagraph.isEmpty {
            blocks.append(MarkdownBlock(
                type: .paragraph,
                content: currentParagraph.joined(separator: " ")
            ))
        }
        
        return blocks
    }
    
    /// Parses inline markdown (bold, italic) within a single text string
    private func parseInlineMarkdown(_ text: String) -> [InlineSegment] {
        var segments: [InlineSegment] = []
        var currentText = ""
        var isBold = false
        var isItalic = false
        var i = text.startIndex
        
        while i < text.endIndex {
            // Check for bold (**text**)
            if i < text.index(text.endIndex, offsetBy: -1),
               text[i] == "*",
               text[text.index(after: i)] == "*" {
                // Flush current segment
                if !currentText.isEmpty {
                    segments.append(InlineSegment(text: currentText, isBold: isBold, isItalic: isItalic))
                    currentText = ""
                }
                // Toggle bold
                isBold.toggle()
                i = text.index(i, offsetBy: 2)
                continue
            }
            
            // Check for italic (*text* or _text_)
            if text[i] == "*" || text[i] == "_" {
                // Make sure it's not part of **
                let nextIndex = text.index(after: i)
                if nextIndex < text.endIndex && text[nextIndex] != "*" && text[nextIndex] != "_" {
                    // Flush current segment
                    if !currentText.isEmpty {
                        segments.append(InlineSegment(text: currentText, isBold: isBold, isItalic: isItalic))
                        currentText = ""
                    }
                    // Toggle italic
                    isItalic.toggle()
                    i = nextIndex
                    continue
                }
            }
            
            // Regular character
            currentText.append(text[i])
            i = text.index(after: i)
        }
        
        // Flush remaining text
        if !currentText.isEmpty {
            segments.append(InlineSegment(text: currentText, isBold: isBold, isItalic: isItalic))
        }
        
        return segments
    }
}

// MARK: - Supporting Types ---------------------------------------------------

private struct MarkdownBlock {
    let id = UUID()
    let type: BlockType
    let content: String
    var listIndex: Int? = nil
    
    enum BlockType {
        case heading1
        case heading2
        case heading3
        case paragraph
        case listItem
        case numberedListItem
    }
}

private struct InlineSegment {
    let text: String
    let isBold: Bool
    let isItalic: Bool
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Rich Markdown") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            CatalystCard {
                VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("AI Insight Preview", icon: "sparkles")
                    
                    MarkdownText(markdown: """
## Individual Analysis for Alice Chen

### Strengths

Alice demonstrates several key capabilities:

- **Code Quality**: Consistently produces clean, maintainable code with excellent test coverage
- **SwiftUI Expertise**: Leading the migration effort with strong architectural decisions
- **Mentoring**: Shows patience and clarity when helping junior developers

### Growth Areas

1. Public speaking and presentations
2. Stakeholder communication at executive level
3. Conference talks and external visibility

### Recommendations

**Short-term focus**: Consider pairing Alice with a senior leader for shadowing opportunities during stakeholder presentations. This will help her observe effective communication patterns.

**Medium-term development**: Encourage internal tech talks to build confidence before pursuing external speaking engagements.

**Long-term goal**: Position Alice as a technical leader who can represent the team externally through conference talks and blog posts.

The combination of her technical skills and growing communication abilities positions her well for senior IC or management tracks.
""")
                }
            }
            .padding()
        }
    }
}

#Preview("Complex Formatting") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            CatalystCard {
                VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("Team Analysis", icon: "person.3.fill")
                    
                    MarkdownText(markdown: """
## Team Health Analysis

### Key Patterns

**Strong technical foundation**: The team shows consistent strength in code quality and system design. Most engineers are at or above expected technical levels for their seniority.

**Emerging leadership gap**: While individual contributors are strong, there's limited evidence of engineers stepping into mentorship or technical leadership roles. This could limit scalability.

**Uneven testing practices**: Testing strength varies significantly across the team. Some engineers consistently write comprehensive tests while others treat it as an afterthought.

### Recommendations

1. **Establish a mentorship program**: Pair senior engineers with more junior team members for structured knowledge transfer
2. **Create testing guidelines**: Document team standards and make test coverage a required part of code review
3. **Rotate on-call responsibilities**: Build system ownership and debugging skills across the entire team

### Watch-outs

- Current sprint velocity is sustainable but leaves little room for unexpected work
- Technical debt in the authentication service is starting to slow down feature development
- Team morale is generally positive but watch for burnout signals as deadlines approach
""")
                }
            }
            .padding()
        }
    }
}
