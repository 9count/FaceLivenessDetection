//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import Foundation

public enum FaceDetectionState: String {
    case faceTooFar = "Please move closer"
    case faceTooClose = "Please move farther"
    case faceFit = "Perfect!"
    case faceFront = "Please turn your face toward the camera"
    case noFace = "Please move your face inside the camera view"
}
