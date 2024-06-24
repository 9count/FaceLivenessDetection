//
//  ContentView.swift
//  TestFaceLivenessDetection
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI
import FaceLivenessDetection

struct ContentView: View {
    @State private var model: LivenessDataModel?
    @State private var verifying = false
    var body: some View {
        NavigationStack {
            FaceLivenessDetectionView { result in
                switch result {
                case .success(let model):
                    debugPrint(model.liveness.rawValue, "recie")
                    self.model = model
                    self.verifying = true
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                }
            }
            .navigationDestination(isPresented: $verifying) {
                if let model {
                    Text(model.liveness.rawValue)

                    Image(uiImage: model.depthImage)
                }
            }
        }

    }
}

#Preview {
    ContentView()
}
