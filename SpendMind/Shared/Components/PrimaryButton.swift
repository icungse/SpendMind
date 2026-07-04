//
//  PrimaryButton.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: LocalizedStringKey
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(AppColor.background)
                }

                Text(title)
                    .appFont(.button)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, AppSpacing.md)
            .foregroundStyle(AppColor.background)
            .background(isDisabled ? AppColor.disabled : AppColor.primary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
    }
}

#Preview {
    PrimaryButton(title: "Add Expense") { }
        .padding(AppSpacing.md)
}
