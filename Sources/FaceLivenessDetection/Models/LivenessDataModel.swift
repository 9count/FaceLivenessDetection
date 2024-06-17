//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/17.
//

import UIKit

public struct LivenessDataModel {
    let liveness: LivenessPredictor.Liveness
    let confidence: Float
    let depthImage: UIImage
    let capturedImage: UIImage
}
