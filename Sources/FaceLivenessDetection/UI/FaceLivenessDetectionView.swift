//
//  SwiftUIView.swift
//
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import Combine
import SwiftUI

public struct FaceLivenessDetectionView: View {
    @StateObject private var viewModel = FaceDetectionViewModel()
    @State private var verifying = false

    var onCompletion: (Result<LivenessDataModel, Error>) -> Void
    // for debug

    public init(onCompletion: @escaping (Result<LivenessDataModel, Error>) -> Void) {
        self.onCompletion = onCompletion
    }

    public var body: some View {
        VStack {
            FaceDetectionView(viewModel: viewModel)
                .overlay {
                    if verifying {
                        CountdownProgressView(2)
                            .frame(width: 100, height: 100)
                    }
                }
                .onChange(of: viewModel.lowLightEnvironment, perform: { value in
                    if value {
                        UIScreen.main.brightness = 1.0
                    }
                })
                .onReceive(viewModel.$predictionResult, perform: { result in
                    guard let capturedImage = result?.capturedImage, let depthImage = result?.depthImage else { return }
                    guard let result else {
                        onCompletion(.failure(LivenessPredictionError.predictionError))
                        return
                    }
                    verifying = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        verifying = false
                        onCompletion(.success(result))
                    }
                })
                .onAppear {
                    viewModel.reset()
                    viewModel.setupDelayTimer()
                }

            if viewModel.instruction == .faceFit && viewModel.livenessDetected {
                Text("Verifying")
                    .foregroundStyle(Color(.greenExtraDark))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity)
            } else {
                InstructionView(instruction: viewModel.instruction)
            }

            Spacer()
        }
    }
}

//#Preview {
//    FaceLivenessDetectionView { result in
//        switch result {
//        case .success(let model):
//            debugPrint(model.liveness.rawValue)
//        case .failure(let error):
//            debugPrint(error.localizedDescription)
//        }
//    }
//}
