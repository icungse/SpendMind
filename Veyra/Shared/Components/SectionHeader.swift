//
//  SectionHeader.swift
//  Veyra
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct SectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .appFont(.headline)
                .foregroundStyle(AppColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .appFont(.footnote)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SectionHeader(title: "Recent Transactions", subtitle: "This week")
        .padding(AppSpacing.md)
}
