//
//  AppColor.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

enum AppColor {
    static let brandBlue = Color(hex: 0x576A8F)
    static let brandLavender = Color(hex: 0xB7BDF7)
    static let brandCream = Color(hex: 0xFFF8DE)
    static let brandOrange = Color(hex: 0xFF7444)

    static let primary = brandBlue
    static let secondary = brandOrange

    static let background = brandCream
    static let surface = Color.white
    static let surfaceAlt = brandLavender.opacity(0.30)
    static let border = Color.black.opacity(0.10)

    static let textPrimary = Color.black.opacity(0.88)
    static let textSecondary = Color.black.opacity(0.60)
    static let textInverse = brandCream
    static let disabled = Color.black.opacity(0.30)
    static let placeholder = Color.black.opacity(0.40)

    static let success = Color(hex: 0x2E7D32)
    static let warning = Color(hex: 0xB26A00)
    static let error = Color(hex: 0xC62828)
    static let info = Color(hex: 0x2563EB)
}

private extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
