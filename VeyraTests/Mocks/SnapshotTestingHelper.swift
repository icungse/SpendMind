//
//  SnapshotTestingHelper.swift
//  VeyraTests
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
                let copyCommand = "mkdir -p VeyraTests/__Snapshots__ && cp \"\(tempURL.path)\" \"VeyraTests/__Snapshots__/\(name).png\""
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

        if !uiImage.isEqualToImage(referenceImage, tolerance: 0.02) {
            let failureURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name)-failed.png")
            try? newData.write(to: failureURL)
            XCTFail("Snapshot mismatch! New snapshot saved to: \(failureURL.path). Reference image: \(validReferenceURL.path)", file: file, line: line)
        }
    }
}

private extension UIImage {
    // pixel-level image comparison helper with tolerance to avoid false failures due to anti-aliasing or rendering platform differences.
    func isEqualToImage(_ image: UIImage, tolerance: Double = 0.02) -> Bool {
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

        if data1 == data2 { return true }

        let totalPixels = width * height
        var differingPixels = 0

        data1.withUnsafeBytes { ptr1 in
            data2.withUnsafeBytes { ptr2 in
                let bytes1 = ptr1.bindMemory(to: UInt8.self)
                let bytes2 = ptr2.bindMemory(to: UInt8.self)

                for i in stride(from: 0, to: totalPixels * 4, by: 4) {
                    let rDiff = abs(Int(bytes1[i]) - Int(bytes2[i]))
                    let gDiff = abs(Int(bytes1[i + 1]) - Int(bytes2[i + 1]))
                    let bDiff = abs(Int(bytes1[i + 2]) - Int(bytes2[i + 2]))
                    let aDiff = abs(Int(bytes1[i + 3]) - Int(bytes2[i + 3]))

                    if rDiff > 3 || gDiff > 3 || bDiff > 3 || aDiff > 3 {
                        differingPixels += 1
                    }
                }
            }
        }

        let mismatchRatio = Double(differingPixels) / Double(totalPixels)
        return mismatchRatio <= tolerance
    }
}
