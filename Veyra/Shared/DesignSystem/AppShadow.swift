//
//  AppShadow.swift
//  Veyra
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let small = AppShadow(color: AppColor.textPrimary.opacity(0.08), radius: 4, x: 0, y: 2)
    static let medium = AppShadow(color: AppColor.textPrimary.opacity(0.10), radius: 8, x: 0, y: 4)
    static let large = AppShadow(color: AppColor.textPrimary.opacity(0.12), radius: 16, x: 0, y: 8)
    static let floating = AppShadow(color: AppColor.textPrimary.opacity(0.16), radius: 24, x: 0, y: 12)
}

extension View {
    func appShadow(_ shadow: AppShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
