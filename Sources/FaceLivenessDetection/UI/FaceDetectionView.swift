//
//  SwiftUIView.swift
//  
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI

public struct FaceDetectionView: View {
    
    @StateObject var detectionViewModel = FaceDetectionViewModel()
    public init() {}
    public var body: some View {
        FaceDetectionViewController(faceDetectionViewModel: detectionViewModel)
            .overlay(alignment: .bottom) {
                VStack {
                    if let result = detectionViewModel.predictionResult {
                        Text(result.rawValue)
                    }
                    Text(detectionViewModel.instruction)
                }
            }
    }
}

class FaceDetectionViewModel: ObservableObject {
    @Published var instruction: String
    @Published var predictionResult: LivenessPredictor.Liveness?
    
    init(instruction: String = "") {
        self.instruction = instruction
    }
}

#Preview {
    FaceDetectionView()
}
