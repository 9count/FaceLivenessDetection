//
//  SwiftUIView.swift
//  
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI
import Combine

public struct _FaceDetectionView: View {
    @ObservedObject var detectionViewModel: FaceDetectionViewModel
    
    public init(viewModel: FaceDetectionViewModel) {
        self._detectionViewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        FaceDetectionViewController(faceDetectionViewModel: detectionViewModel)
            .frame(maxWidth: .infinity, maxHeight: 400)
    }
}

public final class FaceDetectionViewModel: ObservableObject {
    @Published public var instruction: FaceDetectionState = .noFace
    @Published var predictionResult: LivenessPredictor.Liveness?
    @Published var hidePreviewLayer: Bool = false
    let captureImagePublisher = PassthroughSubject<Void, Never>()
    
    public init() {
    }
}
