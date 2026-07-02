//
//  SpendMindUITests.swift
//  SpendMind
//
//  Created by OpenCode
//

import XCTest

final class SpendMindUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["SpendMind"].exists)
    }
}
