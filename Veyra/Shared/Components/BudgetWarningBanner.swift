//
//  BudgetWarningBanner.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import SwiftUI

struct BudgetWarningBanner: View {
    let status: BudgetStatus
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(LocalizedStringKey(message))
                .appFont(.footnote)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: AppSpacing.none)
        }
        .padding(AppSpacing.sm)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.medium)
                .stroke(color.opacity(0.35))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LocalizedStringKey(message))
    }

    private var icon: String {
        status == .exceeded ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill"
    }

    private var color: Color {
        status == .exceeded ? AppColor.error : AppColor.warning
    }
}
