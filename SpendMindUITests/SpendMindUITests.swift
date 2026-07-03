//
//  SpendMindUITests.swift
//  SpendMind
//
//  Created by OpenCode
//

import XCTest

final class SpendMindUITests: XCTestCase {
    @MainActor
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()

        let isTitleVisible = app.staticTexts["SpendMind"].exists
        XCTAssertTrue(isTitleVisible)
    }
}
