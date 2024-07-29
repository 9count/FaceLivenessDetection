//
//  ContentView.swift
//  TestFaceLivenessDetection
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI
import FaceLivenessDetection

struct ContentView: View {
    @State private var faceDataModel: LivenessDataModel?
    @State private var livenessDataModel: LivenessDataModel?

    var body: some View {
        VStack {
            FaceLivenessDetectionView(onFaceDetectedCompletion: handleFaceDetectedCompletion, onCompletion: handleLivenessDetectionCompletion)

            if let faceDataModel {
                PreviewImageView(model: faceDataModel)
            }

            if let livenessDataModel {
                PreviewImageView(model: livenessDataModel)
            }
        }
    }

    private func handleFaceDetectedCompletion(_ result: Result<LivenessDataModel, LivenessDetectionError>) {
        switch result {
            case .success(let model):
                faceDataModel = model
            case .failure(let error):
                debugPrint(error)
        }
    }

    private func handleLivenessDetectionCompletion(_ result: Result<LivenessDataModel, LivenessDetectionError>) {
        switch result {
            case .success(let model):
                livenessDataModel = model
            case .failure(let error):
                debugPrint(error)
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
