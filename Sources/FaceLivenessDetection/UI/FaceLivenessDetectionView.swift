//
//  SwiftUIView.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import SwiftUI

public struct FaceLivenessDetectionView: View {
    @StateObject var viewModel = FaceDetectionViewModel()
    
    public init() {}
    public var body: some View {
        _FaceDetectionView(viewModel: viewModel)
        
        InstructionView(instruction: viewModel.instruction)
        
        if let result = viewModel.predictionResult {
            Text(result.rawValue)
        }
        Button {
            viewModel.captureImagePublisher.send()
        } label: {
            Text("Capture and Predict")
        }
        HStack {
            Button {
                viewModel.hidePreviewLayer.toggle()
            } label: {
                Text("\(viewModel.hidePreviewLayer ? "Show" : "Hide") preview layer")
            }
        }
    }
}

#Preview {
    FaceLivenessDetectionView()
}
