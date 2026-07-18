//
//  CategoryPickerRow.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import SwiftUI

struct CategoryPickerRow: View {
    let category: Category
    let isSelected: Bool
    let subtitle: String?
    let isDisabled: Bool

    init(
        category: Category,
        isSelected: Bool,
        subtitle: String? = nil,
        isDisabled: Bool = false
    ) {
        self.category = category
        self.isSelected = isSelected
        self.subtitle = subtitle
        self.isDisabled = isDisabled
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: category.icon)
                .foregroundStyle(AppColor.textInverse)
                .frame(width: 32, height: 32)
                .background(color.opacity(isDisabled ? 0.45 : 1))
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(category.name)
                    .appFont(.body)
                    .foregroundStyle(isDisabled ? AppColor.disabled : AppColor.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .appFont(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
        }
        .padding(AppSpacing.sm)
        .background(isSelected ? AppColor.surfaceAlt : AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.medium)
                .stroke(isSelected ? color : AppColor.border)
        }
        .opacity(isDisabled ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var color: Color {
        Color(hexString: category.colorHex)
    }

    private var accessibilityLabel: String {
        [category.name, subtitle, isDisabled ? "Unavailable" : nil]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
