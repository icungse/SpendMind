//
//  SpendMindUITests.swift
//  SpendMindTests
//
//  Created by Icung on 03/07/26.
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
