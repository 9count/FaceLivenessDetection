//
//  SwiftUIView.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import SwiftUI
import Combine

public struct FaceLivenessDetectionView: View {
    @StateObject var viewModel = FaceDetectionViewModel()
    let timer = Timer()
    @State private var countDown: TimeInterval?
    
    public init() {}
    public var body: some View {
        _FaceDetectionView(viewModel: viewModel)
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
//            .onReceive(viewModel.$predictionResult, perform: { result in
//                guard let capturedImage = result?.capturedImage, let depthImage = result?.depthImage else { return }
//                UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
//                UIImageWriteToSavedPhotosAlbum(depthImage, nil, nil, nil)
//            })
        
        InstructionView(instruction: viewModel.instruction)
            .onChange(of: viewModel.instruction, perform: { value in
                viewModel.instruction == .faceFit ? startTimer() : stopTimer()
            })

//        if let result = viewModel.predictionResult {
//            Text(result.liveness.rawValue)
//        }

//        HStack {
//            Button {
//                viewModel.hidePreviewLayer.toggle()
//            } label: {
//                Text("\(viewModel.hidePreviewLayer ? "Show" : "Hide") preview layer")
//            }
//        }
    }
    
    func startTimer() {
        stopTimer() // Ensure no existing timer is running
        countDown = 3
        viewModel.countDownPublisher = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
            .sink { time in
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
    FaceLivenessDetectionView()
}
