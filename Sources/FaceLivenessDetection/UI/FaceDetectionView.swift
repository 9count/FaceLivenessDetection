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
        VStack {
            Text(detectionViewModel.instruction)
            FaceDetectionViewController(faceDetectionViewModel: detectionViewModel)
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
