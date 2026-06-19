//
//  CatalystCard.swift
//  Catalyze
//
//  A reusable card component with consistent styling using Material design.
//  Provides the foundation for all card-based layouts in the app.
//

import SwiftUI

// MARK: - Catalyst Card ------------------------------------------------------

struct CatalystCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var radius: CGFloat
    
    init(
        padding: CGFloat = CatalystSpacing.xl,
        radius: CGFloat = CatalystRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.radius = radius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Card Header --------------------------------------------------------

struct CatalystCardHeader: View {
    let title: String
    let icon: String
    var trailing: AnyView?
    
    init(
        _ title: String,
        icon: String,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.icon = icon
        self.trailing = AnyView(trailing())
    }
    
    var body: some View {
        VStack(spacing: CatalystSpacing.lg) {
            HStack {
                Label(title, systemImage: icon)
                    .font(CatalystTypography.sectionTitle)
                
                Spacer()
                
                trailing
            }
            
            Divider()
        }
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Basic Card") {
    ScrollView {
        VStack(spacing: CatalystSpacing.xl) {
            CatalystCard {
                VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("Card Title", icon: "star.fill")
                    
                    Text("This is a sample card with consistent padding and styling.")
                        .font(CatalystTypography.body)
                }
            }
            
            CatalystCard {
                VStack(alignment: .leading, spacing: CatalystSpacing.lg) {
                    CatalystCardHeader("With Trailing Content", icon: "brain.fill") {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Text("This card has trailing content in the header.")
                        .font(CatalystTypography.body)
                }
            }
        }
        .padding(CatalystSpacing.xl)
    }
}
