//
//  SpendMindTest.swift
//  SpendMindTests
//
//  Created by Icung on 03/07/26.
//

import XCTest
import SwiftUI
@testable import SpendMind

final class SpendMindTests: XCTestCase {
    func testAppTargetLoads() {
        XCTAssertTrue(true)
    }

    func testDependenciesCanBeMocked() {
        struct MockDependencies: AppDependencyProviding { }

        var environment = EnvironmentValues()
        environment.dependencies = MockDependencies()

        XCTAssertTrue(environment.dependencies is MockDependencies)
    }
}
