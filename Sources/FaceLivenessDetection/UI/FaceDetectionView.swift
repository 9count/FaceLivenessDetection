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
                Text(detectionViewModel.instruction)
            }
    }
}

class FaceDetectionViewModel: ObservableObject {
    @Published var instruction: String
    
    init(instruction: String = "") {
        self.instruction = instruction
    }
}

#Preview {
    FaceDetectionView()
}
