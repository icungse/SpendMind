//
//  SnapshotTests.swift
//  SpendMindTests
//
//  Created by Icung on 05/07/26.
//

import XCTest
import SwiftUI
@testable import SpendMind

final class SnapshotTests: XCTestCase {
    
    @MainActor
    func testPrimaryButtonSnapshot() {
        let view = PrimaryButton(title: "Add Expense") { }
            .padding()
            .background(Color.white)
            .frame(width: 300)
        
        // assert UI layout and design system color compatibility.
        assertSnapshot(matching: view, named: "PrimaryButton_default")
    }
    
    @MainActor
    func testCardSnapshot() {
        let view = Card {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Balance")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("$1,250.00")
                    .font(.title2)
                    .bold()
            }
        }
        .padding()
        .background(Color.white)
        .frame(width: 300)
        
        assertSnapshot(matching: view, named: "Card_default")
    }
}
