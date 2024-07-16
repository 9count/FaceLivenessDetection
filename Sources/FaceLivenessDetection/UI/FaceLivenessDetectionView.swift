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

    public typealias CompletionHandler = (Result<LivenessDataModel, LivenessDetectionError>) -> Void
    var timeInterval: TimeInterval
    var onCompletion: CompletionHandler

    public init(
        timeInterval: TimeInterval = 3,
        onCompletion: @escaping CompletionHandler) {
        self.onCompletion = onCompletion
        self.timeInterval = timeInterval
    }

    public var body: some View {
        VStack {
            FaceDetectionView(viewModel: viewModel)
                .overlay {
                    if viewModel.showProgress {
                        CountdownProgressView(timeInterval)
                            .frame(width: 100, height: 100)
                    }
                }
                .onChange(of: viewModel.lowLightEnvironment, perform: { value in
                    if value {
                        UIScreen.main.brightness = 1.0
                    }
                })
                .onReceive(viewModel.$predictionResult, perform: { result in
                    guard let result else {
                        return
                    }

                    onCompletion(.success(result))
                    resetDetection()
                })
                .onAppear {
                    resetDetection()
                }

            InstructionView(instruction: viewModel.instruction)

            Spacer()
        }
    }

    private func resetDetection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
            viewModel.reset()
            viewModel.setupDelayTimer()
        }
    }
}

#Preview {
    FaceLivenessDetectionView { result in
        switch result {
            case .success(let model):
                debugPrint(model.liveness.rawValue)
            case .failure(let error):
                debugPrint(error.localizedDescription)
        }
    }
}
