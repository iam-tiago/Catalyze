//
//  CatalystEmptyState.swift
//  Catalyze
//
//  A reusable empty state component for displaying when there's no content.
//  Used across the app for consistent messaging when data is missing.
//

import SwiftUI

// MARK: - Empty State --------------------------------------------------------

struct CatalystEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: CatalystSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: CatalystIconSize.xl))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(CatalystTypography.cardTitle)
            
            Text(message)
                .font(CatalystTypography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let action = action, let actionLabel = actionLabel {
                Button(action: action) {
                    Label(actionLabel, systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, CatalystSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CatalystSpacing.xxl)
    }
}

// MARK: - Preview ------------------------------------------------------------

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: CatalystSpacing.xl) {
            CatalystCard {
                CatalystEmptyState(
                    icon: "person.3.slash",
                    title: "No team members yet",
                    message: "Add members in the Team tab to generate insights."
                )
            }
            
            CatalystCard {
                CatalystEmptyState(
                    icon: "doc.text.slash",
                    title: "No observations",
                    message: "Start tracking team member observations to get better insights.",
                    actionLabel: "Add Observation",
                    action: { print("Add tapped") }
                )
            }
            
            CatalystCard {
                CatalystEmptyState(
                    icon: "brain.slash",
                    title: "No insights yet",
                    message: "Generate your first AI insight to see recommendations."
                )
            }
        }
        .padding(CatalystSpacing.xl)
    }
}
