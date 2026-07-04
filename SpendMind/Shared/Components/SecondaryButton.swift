//
//  SecondaryButton.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct SecondaryButton: View {
    let title: LocalizedStringKey
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(isDisabled ? AppColor.disabled : AppColor.primary)
                }

                Text(title)
                    .appFont(.button)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, AppSpacing.md)
            .foregroundStyle(isDisabled ? AppColor.disabled : AppColor.primary)
            .overlay {
                RoundedRectangle(cornerRadius: Radius.medium)
                    .stroke(isDisabled ? AppColor.disabled : AppColor.border)
            }
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
    }
}

#Preview {
    SecondaryButton(title: "Cancel") { }
        .padding(AppSpacing.md)
}
