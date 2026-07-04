//
//  LoadingView.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct LoadingView: View {
    var title: LocalizedStringKey?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .tint(AppColor.primary)

            if let title {
                Text(title)
                    .appFont(.body)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.lg)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    LoadingView(title: "Loading")
}
