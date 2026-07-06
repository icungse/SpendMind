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

    static let background = Color(light: brandCream, dark: Color(hex: 0x121826))
    static let surface = Color(light: .white, dark: Color(hex: 0x1B2436))
    static let surfaceAlt = Color(light: brandLavender.opacity(0.30), dark: Color(hex: 0x27324A))
    static let border = Color(light: .black.opacity(0.10), dark: .white.opacity(0.14))

    static let textPrimary = Color(light: .black.opacity(0.88), dark: brandCream)
    static let textSecondary = Color(light: .black.opacity(0.60), dark: brandCream.opacity(0.72))
    static let textInverse = Color(light: brandCream, dark: Color(hex: 0x121826))
    static let disabled = Color(light: .black.opacity(0.30), dark: .white.opacity(0.30))
    static let placeholder = Color(light: .black.opacity(0.40), dark: .white.opacity(0.45))

    static let success = Color(light: Color(hex: 0x2E7D32), dark: Color(hex: 0x6DD58C))
    static let warning = Color(light: Color(hex: 0xB26A00), dark: Color(hex: 0xFFD166))
    static let error = Color(light: Color(hex: 0xC62828), dark: Color(hex: 0xFF8A80))
    static let info = Color(light: Color(hex: 0x2563EB), dark: Color(hex: 0x8AB4FF))
}
