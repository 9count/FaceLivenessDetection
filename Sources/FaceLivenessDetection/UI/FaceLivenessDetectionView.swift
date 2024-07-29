//
//  SwiftUIView.swift
//
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import Combine
import SwiftUI

///
/// This view integrates with `FaceDetectionViewModel` to manage the detection process
/// and provides feedback on the detection state through a series of subviews including
/// a countdown timer and instructional text.
public struct FaceLivenessDetectionView: View {
    @StateObject private var viewModel = FaceDetectionViewModel()

    /// Typealias for the completion handler to manage success and failure.
    public typealias CompletionHandler = (Result<LivenessDataModel, LivenessDetectionError>) -> Void

    /// The time interval for the fake verifying loading progress UI.
    var timeInterval: TimeInterval

    /// Completion handler to be called when face is first detected during the current session.
    var onFaceDetectedCompletion: CompletionHandler?

    /// Completion handler to be called with the result of the liveness detection.
    var onCompletion: CompletionHandler

    /// Initializes a new instance of the face liveness detection view.
    ///
    /// - Parameters:
    ///   - timeInterval: The time interval for the fake verifying loading progress UI (default is 3 seconds).
    ///   - onCompletion: The completion handler to call with the detection result.
    public init(
        timeInterval: TimeInterval = 3,
        onFaceDetectedCompletion: CompletionHandler? = nil,
        onCompletion: @escaping CompletionHandler) {
        self.onFaceDetectedCompletion = onFaceDetectedCompletion
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
                .onReceive(viewModel.$faceDetectedResult) { result in
                    guard let result else { return }
                    onFaceDetectedCompletion?(.success(result))
                }
                .onReceive(viewModel.$predictionResult, perform: { result in
                    guard let result else { return }
                    onCompletion(.success(result))
                    resetDetectionFlow()
                })
                .onAppear {
                    viewModel.setupDelayTimer()
                }

            InstructionView(instruction: viewModel.instruction)

            Spacer()
        }
    }

    /// Resets the detection process after a specified time interval and prepares for a new detection cycle.
    private func resetDetectionFlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval + 2.0) {
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
