import XCTest
@testable import FaceLivenessDetection

final class FaceLivenessDetectionTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
    
    func testInitialFaceDetectionState() {
        let vm = FaceDetectionViewModel()
        
        XCTAssertEqual(vm.instruction, FaceDetectionState.noFace)
        XCTAssertEqual(vm.livenessDetected, false)
    }
}
