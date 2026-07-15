//
//  BudgetCardBodyView.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import SwiftUI

struct BudgetCardBodyView: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let amount: String
    let spent: String
    let remaining: String
    let progress: Decimal
    let status: BudgetStatus
    let isTotal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(AppColor.textInverse)
                    .frame(width: 40, height: 40)
                    .background(iconColor)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .appFont(.caption)
                        .foregroundStyle(isTotal ? AppColor.primary : AppColor.textSecondary)
                }

                Spacer(minLength: AppSpacing.sm)

                Text(statusText)
                    .appFont(.caption)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(spacing: AppSpacing.sm) {
                amountRow(label: "Budget", value: amount)
                amountRow(label: "Spent", value: spent)
                amountRow(label: "Remaining", value: remaining)
            }

            BudgetProgressIndicatorView(budgetName: title, progress: progress, status: status)
        }
        .padding(isTotal ? AppSpacing.xs : AppSpacing.none)
        .background(isTotal ? AppColor.surfaceAlt.opacity(0.35) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle), budget \(amount), spent \(spent), remaining \(remaining), \(percentageText) used, status \(statusText)")
    }

    private var statusText: String {
        switch status {
        case .safe: "Safe"
        case .warning: "Warning"
        case .exceeded: "Exceeded"
        }
    }

    private var statusColor: Color {
        switch status {
        case .safe: AppColor.success
        case .warning: AppColor.warning
        case .exceeded: AppColor.error
        }
    }

    private var percentageText: String {
        let value = max(0, NSDecimalNumber(decimal: progress).doubleValue)
        return "\(Int((value * 100).rounded()))%"
    }

    private func amountRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)

            Spacer(minLength: AppSpacing.md)

            Text(value)
                .appFont(.bodyBold)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.8)
        }
    }
}
