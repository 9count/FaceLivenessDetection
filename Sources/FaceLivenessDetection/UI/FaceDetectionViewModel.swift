//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/27.
//

import Foundation
import Combine

public final class FaceDetectionViewModel: ObservableObject {
    /// Current state of face detection, indicating if a face is present or not.
    @Published public var instruction: FaceDetectionState = .noFace {
        didSet {
            if instruction == .faceFit {
                showProgress = true
                captureImagePublisher.send()
            }
        }
    }

    /// Stores the prediction results from the liveness detection model.
    @Published public var predictionResult: LivenessDataModel?
    /// Controls the visibility of the camera preview layer. (For Debug)
    @Published var hidePreviewLayer = false

    /// Indicates if the environment has low light conditions.
    @Published var lowLightEnvironment = false
    /// Flag to determine if the face can be analyzed.
    @Published public var canAnalyzeFace = false

    /// Indicates whether the app is currently showing verifying progress.
    @Published public var showProgress = false

    /// Publisher to trigger an image capture.
    public let captureImagePublisher = PassthroughSubject<Void, Never>()

    /// Publisher to signal a resume in the capture session.
    public let resumeSessionPublisher = PassthroughSubject<Void, Never>()

    /// Set of AnyCancellable for storing subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// Resets the view model to its initial state.
    public func reset() {
        instruction = .noFace
        predictionResult = nil
        canAnalyzeFace = false
        showProgress = false
    }

    /// Sets up a delay timer after which the face can be analyzed.
    public func setupDelayTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.canAnalyzeFace = true
            self.resumeSessionPublisher.send()
        }
    }
}
