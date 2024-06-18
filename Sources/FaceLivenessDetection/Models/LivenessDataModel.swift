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
}

public enum LivenessPredictionError: Error {
    case predictionError
}
