//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/27.
//

import Foundation
import Combine

public final class FaceDetectionViewModel: ObservableObject {
    @Published public var instruction: FaceDetectionState = .noFace
    @Published public var livenessDetected = false
    @Published var predictionResult: LivenessDataModel?
    @Published var hidePreviewLayer = false
    @Published var lowLightEnvironment = false
    @Published var captured = false
    @Published var canAnalyzeFace = false

    let captureImagePublisher = PassthroughSubject<Void, Never>()
    var countDownPublisher: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupPublishers()
    }

    private func setupPublishers() {
        Publishers.CombineLatest3($instruction, $livenessDetected, $captured)
            .receive(on: RunLoop.main)
            .filter { instruction, livenessDetected, captured in
                return instruction == .faceFit && livenessDetected && !captured
            }
            .sink { [weak self] _ in
                self?.captureImagePublisher.send()
                self?.captured = true
            }
            .store(in: &cancellables)
    }

    public func reset() {
        instruction = .noFace
        livenessDetected = false
        predictionResult = nil
        captured = false
        canAnalyzeFace = false
    }

    public func setupDelayTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.canAnalyzeFace = true
        }
    }
}
