//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/17.
//

import UIKit

/// `LivenessDataModel` encapsulates the results of a liveness detection operation.
///
/// This struct stores all relevant data obtained during the liveness detection process, which is typically used for validating the presence and authenticity of a user in front of the camera.
///
/// Properties:
/// - `liveness`: An enum value of type `LivenessPredictor.Liveness` indicating the liveness status (e.g., real, fake).
/// - `confidence`: A `Float` value representing the confidence level of the liveness prediction, where a higher value indicates greater confidence.
/// - `depthImage`: A `UIImage` object containing the depth information of the captured scene, used for analyzing the spatial features of the face to assist in liveness detection.
/// - `capturedImage`: A `UIImage` object representing the actual image captured during the detection process, used for further processing or auditing.
///
/// Usage:
/// This struct is typically used to store and pass around the data resulting from a liveness check, allowing for subsequent actions based on the liveness result and confidence level, such as authenticating a user or flagging a potential spoofing attempt.
///
/// Example:
/// ```swift
/// let livenessData = LivenessDataModel(
///     liveness: .real,
///     confidence: 0.98,
///     depthImage: depthUIImage,
///     capturedImage: userUIImage)
/// ```
/// Here, `livenessData` contains all the necessary details to evaluate the result of the liveness detection operation.
public struct LivenessDataModel {
    public let liveness: LivenessPredictor.Liveness
    public let confidence: Float
    public let depthImage: UIImage
    public let capturedImage: UIImage

    public init(
        liveness: LivenessPredictor.Liveness,
        confidence: Float,
        depthImage: UIImage,
        capturedImage: UIImage) {
        self.liveness = liveness
        self.confidence = confidence
        self.depthImage = depthImage
        self.capturedImage = capturedImage
    }
}

public enum LivenessDetectionError: Error {
    case predictionError
    case captureImageMissingError
}
