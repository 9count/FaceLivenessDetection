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
    let timer = Timer()
    @State private var countDown: TimeInterval?
    var onCompletion: (Result<LivenessDataModel, Error>) -> Void

    public init(onCompletion: @escaping (Result<LivenessDataModel, Error>) -> Void) {
        self.onCompletion = onCompletion
    }

    public var body: some View {
        VStack {
            FaceDetectionView(viewModel: viewModel)
                .overlay {
                    if let countDown {
                        Text("\(Int(countDown))")
                            .font(.veryLargeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.8))
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
                    onCompletion(.success(result))
                })

            InstructionView(instruction: viewModel.instruction)
                .onChange(of: viewModel.instruction, perform: { _ in
                    viewModel.instruction == .faceFit ? startTimer() : stopTimer()
                })

            Spacer()
        }
    }

    func startTimer() {
        stopTimer() // Ensure no existing timer is running
        countDown = 3
        viewModel.countDownPublisher = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()
            .sink { _ in
                guard let countDown else { return }
                if countDown <= 0 {
                    viewModel.captureImagePublisher.send()
                    stopTimer()
                } else {
                    self.countDown = countDown - 1
                }
            }
    }

    func stopTimer() {
        viewModel.countDownPublisher?.cancel()
        countDown = nil
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
