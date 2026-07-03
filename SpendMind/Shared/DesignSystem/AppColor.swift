//
//  AppColor.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

enum AppColor {
    static let primary = Color.accentColor

    static let background = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let border = Color(uiColor: .separator)

    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let disabled = Color(uiColor: .tertiaryLabel)
    static let placeholder = Color(uiColor: .placeholderText)

    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemOrange)
    static let error = Color(uiColor: .systemRed)
    static let info = Color(uiColor: .systemBlue)
}
