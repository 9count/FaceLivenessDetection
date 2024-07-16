//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/27.
//

import Foundation
import Combine

public final class FaceDetectionViewModel: ObservableObject {
    @Published public var instruction: FaceDetectionState = .noFace {
        didSet {
            if instruction == .faceFit {
                showProgress = true
                captureImagePublisher.send()
            }
        }
    }

    @Published var predictionResult: LivenessDataModel?
    @Published var hidePreviewLayer = false
    @Published var lowLightEnvironment = false
    @Published var canAnalyzeFace = false
    @Published var showProgress = false

    let captureImagePublisher = PassthroughSubject<Void, Never>()
    let resumeSessionPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    public func reset() {
        instruction = .noFace
        predictionResult = nil
        canAnalyzeFace = false
        showProgress = false
    }

    public func setupDelayTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.canAnalyzeFace = true
            self.resumeSessionPublisher.send()
        }
    }
}
