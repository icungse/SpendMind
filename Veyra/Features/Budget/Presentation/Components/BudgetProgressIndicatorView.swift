//
//  BudgetProgressIndicatorView.swift
//  Veyra
//
//  Created by Icung on 15/07/26.
//

import SwiftUI

struct BudgetProgressIndicatorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let budgetName: String
    let progress: Decimal
    let status: BudgetStatus

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Label(statusText, systemImage: statusIcon)
                    .appFont(.caption)
                    .foregroundStyle(statusColor)

                Spacer()

                Text(String.localizedStringWithFormat(String(localized: "budget.used"), percentageText))
                    .appFont(.caption)
                    .foregroundStyle(AppColor.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.surfaceAlt)

                    Capsule()
                        .fill(statusColor)
                        .frame(width: geometry.size.width * min(progressValue, 1))

                    if progressValue > 1 {
                        Capsule()
                            .stroke(statusColor, lineWidth: 2)
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: progressValue)
            }
            .frame(height: AppSpacing.base)

            if progressValue > 1 {
                Text(String.localizedStringWithFormat(String(localized: "budget.over_budget"), overBudgetText))
                    .appFont(.caption2)
                    .foregroundStyle(statusColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String.localizedStringWithFormat(
            String(localized: "budget.accessibility.progress"),
            budgetName,
            percentageText,
            statusText
        ))
    }

    private var progressValue: Double {
        max(0, NSDecimalNumber(decimal: progress).doubleValue)
    }

    private var percentageText: String {
        "\(Int((progressValue * 100).rounded()))%"
    }

    private var overBudgetText: String {
        "\(Int(((progressValue - 1) * 100).rounded()))%"
    }

    private var statusText: String {
        switch status {
        case .safe: String(localized: "budget.safe")
        case .warning: String(localized: "budget.warning")
        case .exceeded: String(localized: "budget.exceeded")
        }
    }

    private var statusIcon: String {
        switch status {
        case .safe: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .exceeded: "xmark.octagon.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .safe: AppColor.success
        case .warning: AppColor.warning
        case .exceeded: AppColor.error
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        BudgetProgressIndicatorView(budgetName: "Groceries", progress: 0, status: .safe)
        BudgetProgressIndicatorView(budgetName: "Food", progress: 0.45, status: .safe)
        BudgetProgressIndicatorView(budgetName: "Transport", progress: 0.85, status: .warning)
        BudgetProgressIndicatorView(budgetName: "Shopping", progress: 1.25, status: .exceeded)
    }
    .padding(AppSpacing.md)
    .background(AppColor.background)
}
