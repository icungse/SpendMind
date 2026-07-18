//
//  Color+Extensions.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import SwiftUI

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        // invalid stored category colors fall back to brand blue; add validation when categories are editable.
        let value = UInt(hex, radix: 16) ?? 0x576A8F
        self.init(hex: value)
    }
}
