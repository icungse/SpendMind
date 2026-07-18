//
//  Typography.swift
//  Veyra
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

enum PoppinsWeight: String {
    case regular = "Poppins-Regular"
    case medium = "Poppins-Medium"
    case semibold = "Poppins-SemiBold"
    case bold = "Poppins-Bold"
    case black = "Poppins-Black"
}

extension Font {
    static func poppins(_ weight: PoppinsWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: textStyle)
    }
}

enum Typography {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case bodyBold
    case callout
    case caption
    case caption2
    case footnote
    case button
    case label

    var font: Font {
        switch self {
        case .largeTitle:
            .poppins(.black, size: 34, relativeTo: .largeTitle)
        case .title1:
            .poppins(.semibold, size: 28, relativeTo: .title)
        case .title2:
            .poppins(.semibold, size: 22, relativeTo: .title2)
        case .title3:
            .poppins(.semibold, size: 20, relativeTo: .title3)
        case .headline:
            .poppins(.semibold, size: 17, relativeTo: .headline)
        case .body:
            .poppins(.regular, size: 17, relativeTo: .body)
        case .bodyBold:
            .poppins(.bold, size: 17, relativeTo: .body)
        case .callout:
            .poppins(.regular, size: 16, relativeTo: .callout)
        case .caption:
            .poppins(.regular, size: 12, relativeTo: .caption)
        case .caption2:
            .poppins(.regular, size: 11, relativeTo: .caption2)
        case .footnote:
            .poppins(.regular, size: 13, relativeTo: .footnote)
        case .button:
            .poppins(.semibold, size: 16, relativeTo: .headline)
        case .label:
            .poppins(.regular, size: 15, relativeTo: .subheadline)
        }
    }
}

extension View {
    func appFont(_ typography: Typography) -> some View {
        font(typography.font)
    }
}
