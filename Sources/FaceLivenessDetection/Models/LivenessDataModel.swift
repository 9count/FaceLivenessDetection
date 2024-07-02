//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/17.
//

import UIKit

public struct LivenessDataModel {
    public let liveness: LivenessPredictor.Liveness
    public let confidence: Float
    public let depthImage: UIImage
    public let capturedImage: UIImage
    public init(liveness: LivenessPredictor.Liveness, confidence: Float, depthImage: UIImage, capturedImage: UIImage) {
        self.liveness = liveness
        self.confidence = confidence
        self.depthImage = depthImage
        self.capturedImage = capturedImage
    }
}

public enum LivenessPredictionError: Error {
    case predictionError
}
