//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import Foundation

public enum FaceDetectionState: String {
    case faceTooFar = "Please move closer and fit your face in this camera view"
    case faceTooClose = "Please move farer and fit your face in this camera view"
    case faceFit = "Perfect!Now please hold your position for a few seconds while we verify..."
    case faceRight = "Please turn your face right"
    case faceLeft = "Please turn your face left"
    case noFace = "Detecting Face in the camera view..."
}
