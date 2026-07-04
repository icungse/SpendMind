//
//  Typography.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

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
            .largeTitle
        case .title1:
            .title
        case .title2:
            .title2
        case .title3:
            .title3
        case .headline:
            .headline
        case .body:
            .body
        case .bodyBold:
            .body.bold()
        case .callout:
            .callout
        case .caption:
            .caption
        case .caption2:
            .caption2
        case .footnote:
            .footnote
        case .button:
            .headline
        case .label:
            .subheadline
        }
    }
}

extension View {
    func appFont(_ typography: Typography) -> some View {
        font(typography.font)
    }
}
