//
//  EmptyState.swift
//  Veyra
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct EmptyState: View {
    let title: LocalizedStringKey
    var message: LocalizedStringKey?
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text(title)
                .appFont(.headline)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .appFont(.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, AppSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    EmptyState(
        title: "No transactions yet",
        message: "Add your first expense to start tracking.",
        actionTitle: "Add Expense"
    ) { }
}
