//
//  View+Extensions.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import SwiftUI

extension View {
    /// one conditional modifier beats custom wrappers until repeated UI needs more.
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
