//
//  Card.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.large))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.large)
                    .stroke(AppColor.border)
            }
            .appShadow(.small)
    }
}

#Preview {
    Card {
        Text("Balance")
            .appFont(.headline)
            .foregroundStyle(AppColor.textPrimary)
    }
    .padding(AppSpacing.md)
}
