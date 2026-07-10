//
//  ExpenseRow.swift
//  SpendMind
//
//  Created by Icung on 10/07/26.
//

import SwiftUI

struct ExpenseRow: View {
    let title: String
    let categoryName: String
    let categoryIcon: String
    let categoryColor: Color
    let date: Date
    let amount: Decimal
    let currencyCode: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: categoryIcon)
                .foregroundStyle(AppColor.textInverse)
                .frame(width: 36, height: 36)
                .background(categoryColor)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .appFont(.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text("\(categoryName) • \(date.formatted(.dateTime.month(.abbreviated).day()))")
                    .appFont(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(amount.formattedCurrency(code: currencyCode))
                .appFont(.headline)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    ExpenseRow(
        title: "Starbucks",
        categoryName: "Food",
        categoryIcon: "fork.knife",
        categoryColor: Color(hexString: "#FF7444"),
        date: .now,
        amount: 65_000,
        currencyCode: "IDR"
    )
    .padding(AppSpacing.md)
    .background(AppColor.background)
}

#Preview("Dark") {
    ExpenseRow(
        title: "Train Ticket",
        categoryName: "Transportation",
        categoryIcon: "car.fill",
        categoryColor: Color(hexString: "#576A8F"),
        date: .now,
        amount: 25_000,
        currencyCode: "IDR"
    )
    .padding(AppSpacing.md)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
