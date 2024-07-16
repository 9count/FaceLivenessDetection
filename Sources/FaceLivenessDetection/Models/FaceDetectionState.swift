//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import Foundation

/// `FaceDetectionState` defines the various states of face detection within a camera view, providing user feedback for each state.
///
/// Each case in the enum represents a different condition of face detection:
/// - `noFace`: The camera does not detect any face within the view, or a face is detected but no liveness has been established. It prompts the user to position their face inside the camera's viewing area.
/// - `faceTooFar`: The detected face is too far from the camera. It advises the user to move closer to the camera to ensure better accuracy in face detection.
/// - `faceTooClose`: The detected face is too close to the camera. It advises the user to move farther away from the camera to fit their face properly within the view.
/// - `faceFit`: The face is properly positioned within the camera view and passes the liveness check.
/// - `faceFront`: The face is detected but not oriented towards the camera. It prompts the user to turn their face directly toward the camera to proceed with further processing.
///
/// This enum is primarily used to provide clear, contextual feedback to the user based on the current state of face detection, improving user interaction and the effectiveness of the face detection process.
public enum FaceDetectionState: String {
    case noFace = "Please move your face inside the camera view"
    case faceTooFar = "Please move closer"
    case faceTooClose = "Please move farther"
    case faceFit = "Verifying"
    case faceFront = "Please turn your face toward the camera"
}
