//
//  SnapshotTestingHelper.swift
//  SpendMindTests
//
//  Created by Icung on 05/07/26.
//

import SwiftUI
import XCTest

extension XCTestCase {
    // custom lightweight snapshot testing helper using iOS 16 ImageRenderer to avoid third-party dependencies.
    @MainActor
    func assertSnapshot(
        matching view: some View,
        named name: String,
        record: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // Standard retina scale for snapshot stability

        guard let uiImage = renderer.uiImage else {
            XCTFail("Failed to render SwiftUI view to image", file: file, line: line)
            return
        }

        guard let newData = uiImage.pngData() else {
            XCTFail("Failed to generate PNG data from rendered image", file: file, line: line)
            return
        }

        let bundle = Bundle(for: Self.self)
        let referenceURL = bundle.url(forResource: name, withExtension: "png")

        if record || referenceURL == nil {
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let tempURL = tempDir.appendingPathComponent("\(name).png")
            do {
                try newData.write(to: tempURL)
                let copyCommand = "mkdir -p SpendMindTests/__Snapshots__ && cp \"\(tempURL.path)\" \"SpendMindTests/__Snapshots__/\(name).png\""
                XCTFail("Snapshot reference not found in target bundle resources. Recorded temp snapshot at: \(tempURL.path). Copy to project snapshot directory using:\n\(copyCommand)\nThen regenerate the project workspace via 'tuist generate --no-open'.", file: file, line: line)
            } catch {
                XCTFail("Failed to record snapshot fallback to temp: \(error.localizedDescription)", file: file, line: line)
            }
            return
        }

        guard let validReferenceURL = referenceURL,
              let referenceData = try? Data(contentsOf: validReferenceURL),
              let referenceImage = UIImage(data: referenceData) else {
            XCTFail("Failed to load reference image resource: \(name).png", file: file, line: line)
            return
        }

        if !uiImage.isEqualToImage(referenceImage) {
            let failureURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name)-failed.png")
            try? newData.write(to: failureURL)
            XCTFail("Snapshot mismatch! New snapshot saved to: \(failureURL.path). Reference image: \(validReferenceURL.path)", file: file, line: line)
        }
    }
}

private extension UIImage {
    // pixel-level image comparison helper to avoid false failures due to PNG metadata or color-space profile tag mismatches.
    func isEqualToImage(_ image: UIImage) -> Bool {
        guard let cgImage1 = self.cgImage, let cgImage2 = image.cgImage else { return false }
        guard cgImage1.width == cgImage2.width && cgImage1.height == cgImage2.height else { return false }

        let width = cgImage1.width
        let height = cgImage1.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        var data1 = Data(count: height * bytesPerRow)
        var data2 = Data(count: height * bytesPerRow)

        data1.withUnsafeMutableBytes { ptr1 in
            guard let context1 = CGContext(
                data: ptr1.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return }
            context1.draw(cgImage1, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        data2.withUnsafeMutableBytes { ptr2 in
            guard let context2 = CGContext(
                data: ptr2.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return }
            context2.draw(cgImage2, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return data1 == data2
    }
}
