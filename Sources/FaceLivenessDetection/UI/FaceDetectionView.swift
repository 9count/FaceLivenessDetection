//
//  SwiftUIView.swift
//  
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI
import Combine

public struct FaceDetectionView: View {
    @StateObject var detectionViewModel = FaceDetectionViewModel()
    
    public init() {}

    public var body: some View {
        VStack {
            FaceDetectionViewController(faceDetectionViewModel: detectionViewModel)
                .frame(maxWidth: .infinity, maxHeight: 400)

            // Fix: don't know why adding this code causes ui update problem
//            Text(detectionViewModel.instruction.rawValue)
//                .foregroundStyle(detectionViewModel.instruction == .faceFit ? .green : .red)
//                .font(.headline)
//                .multilineTextAlignment(.center)
//                .foregroundColor(Color(red: 1, green: 0, blue: 0.37))
//                .frame(width: 260, alignment: .top)

            if let result = detectionViewModel.predictionResult {
                Text(result.rawValue)
            }
            Button {
                detectionViewModel.captureImagePublisher.send()
            } label: {
                Text("Capture and Predict")
            }
            HStack {
                Button {
                    detectionViewModel.hidePreviewLayer.toggle()
                } label: {
                    Text("\(detectionViewModel.hidePreviewLayer ? "Show" : "Hide") preview layer")
                }
            }
        }
    }
}

class FaceDetectionViewModel: ObservableObject {
    @Published var instruction: FaceDetectionState = .noFace
    @Published var predictionResult: LivenessPredictor.Liveness?
    @Published var hidePreviewLayer: Bool = false
    let captureImagePublisher = PassthroughSubject<Void, Never>()
    
    enum FaceDetectionState: String {
        case faceTooFar = "Please move closer and fit your face in this camera view"
        case faceTooClose = "Please move farer and fit your face in this camera view"
        case faceFit = "Perfect!Now please hold your position for a few seconds while we verify..."
        case faceRight = "Please turn your face right"
        case faceLeft = "Please turn your face left"
        case noFace = "Detecting Face in the camera view..."
    }
    
    init() {
    }
}

#Preview {
    FaceDetectionView()
}
