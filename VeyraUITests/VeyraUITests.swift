//
//  VeyraUITests.swift
//  VeyraTests
//
//  Created by Icung on 03/07/26.
//

import XCTest

final class VeyraUITests: XCTestCase {
    @MainActor
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()

        let exists = app.staticTexts["Total Balance"].waitForExistence(timeout: 5.0)
        XCTAssertTrue(exists, "Dashboard was not shown within timeout")
    }
}
