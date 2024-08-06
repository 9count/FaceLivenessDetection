//
//  ContentView.swift
//  TestFaceLivenessDetection
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI
import FaceLivenessDetection

class LivenessResult: ObservableObject {
    var faceDataModel: LivenessDataModel?
    var livenessDataModel: LivenessDataModel?

    func addFaceDataModel(_ dataModel: LivenessDataModel) {
        self.faceDataModel = dataModel
    }

    func addLivenessDataModel(_ dataModel: LivenessDataModel) {
        self.livenessDataModel = dataModel
    }
}

struct ContentView: View {
    private enum Stage: CaseIterable {
        case verifying
        case failure
        case success
    }
    @State private var path: [Stage] = []
    @State private var stage: Stage? = .verifying

    @StateObject private var livenessResult: LivenessResult = .init()

    var body: some View {
        VStack {
            if #available(iOS 16, *) {
                NavigationStack(path: $path) {
                    content
                }
            } else {
                NavigationView {
                    content
                }
            }
        }
    }

    private func handleFaceDetectedCompletion(_ result: Result<LivenessDataModel, LivenessDetectionError>) {
        switch result {
            case .success(let model):
                livenessResult.addFaceDataModel(model)
            case .failure(let error):
                stage = .failure
                path.append(.failure)
        }
    }

    private func handleLivenessDetectionCompletion(_ result: Result<LivenessDataModel, LivenessDetectionError>) {
        switch result {
            case .success(let model):
                livenessResult.addLivenessDataModel(model)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    stage = .success
                    path.append(.success)
                }
            case .failure(let error):
                stage = .failure
                path.append(.failure)
        }
    }

    @ViewBuilder
     var content: some View {
        FaceLivenessDetectionView(
            timeInterval: 3,
            onCompletion: handleLivenessDetectionCompletion
        )
        .navigationDestinationWrapper(for: Stage.self, isActive: $stage) { stage in
            switch stage {
                case .verifying:
                    FaceLivenessDetectionView(
                        timeInterval: 3,
                        onFaceDetectedCompletion: handleFaceDetectedCompletion,
                        onCompletion: handleLivenessDetectionCompletion
                    )
                case .success:
                    VStack {
                        if let faceDataModel = livenessResult.faceDataModel {
                            PreviewImageView(model: faceDataModel)
                        }

                        if let livenessDataModel = livenessResult.livenessDataModel {
                            PreviewImageView(model: livenessDataModel)
                        }
                    }
                case .failure:
                    Text("Fail stage")
            }
        }
    }
}

struct PreviewImageView: View {
    let model: LivenessDataModel

    var body: some View {
        VStack(spacing: 8) {
            Text(model.liveness.rawValue) + Text("  \(model.confidence * 100)%")
            HStack(spacing: 16) {
                Image(uiImage: model.capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)

                Image(uiImage: model.depthImage)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(90))
                    .frame(width: 100)
            }
        }
    }
}

#Preview {
    ContentView()
}
