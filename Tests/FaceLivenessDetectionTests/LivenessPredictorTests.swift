//
//  LivenessPredictorTests.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/20.
//

import XCTest
@testable import FaceLivenessDetection

final class LivenessPredictorTests: XCTestCase {
    let livenessPredictor = LivenessPredictor()
    
    func testFakeLiveness() {
        let expectation = expectation(description: "completion handler on predicting liveness")
        let expectResult = LivenessPredictor.Liveness.fake

        let cgImage = CGImage.createSampleCGImage()!
        let uiImage = UIImage(cgImage: cgImage)
        do {
            try livenessPredictor.makePrediction(for: uiImage) { liveness, confidence in
                XCTAssertEqual(liveness, expectResult)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 3)

        } catch {

        }

    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}

fileprivate extension CGImage {
    static func createSampleCGImage() -> CGImage? {
        let width = 100
        let height = 100
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)

        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return context?.makeImage()
    }
}
