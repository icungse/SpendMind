//
//  SplashViewTests.swift
//  SpendMindTests
//
//  Created by Icung on 05/07/26.
//

import XCTest
import SwiftUI
@testable import SpendMind

final class SplashViewTests: XCTestCase {
    @MainActor
    func testSplashViewTransitionsToFinished() async {
        var isFinished = false
        let binding = Binding<Bool>(
            get: { isFinished },
            set: { isFinished = $0 }
        )

        let view = SplashView(isFinished: binding)
        let hostingController = UIHostingController(rootView: view)

        // Trigger load/appear by placing in a window
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        let expectation = expectation(description: "Splash animation completes and sets isFinished to true")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(isFinished)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3.0)
    }
}
