//
//  FaceDetectionView.swift
//
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import Combine
import SwiftUI

public struct FaceDetectionView: View {
    @ObservedObject var detectionViewModel: FaceDetectionViewModel

    public init(viewModel: FaceDetectionViewModel) {
        self._detectionViewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        FaceDetectionViewControllerSwiftUI(faceDetectionViewModel: detectionViewModel)
            .frame(maxWidth: .infinity, maxHeight: 400)
    }
}

public final class FaceDetectionViewModel: ObservableObject {
    @Published public var instruction: FaceDetectionState = .noFace
    @Published public var livenessDetected = false
    @Published var predictionResult: LivenessDataModel?
    @Published var hidePreviewLayer = false
    @Published var lowLightEnvironment = false

    let captureImagePublisher = PassthroughSubject<Void, Never>()
    var countDownPublisher: AnyCancellable?

    public init() {
    }

    public func reset() {
        instruction = .noFace
        livenessDetected = false
        predictionResult = nil
    }
}
