//
//  SpendMindApp.swift
//  SpendMind
//
//  Created by OpenCode
//

import SwiftUI

@main
struct SpendMindApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct ContentView: View {
    var body: some View {
        Text(verbatim: "SpendMind")
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ContentView()
}
