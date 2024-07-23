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
    var body: some View {
        NavigationView {
            FaceLivenessDetectionView { result in
                switch result {
                case .success(let model):
                    debugPrint(model.liveness.rawValue, "liveness result")
                    self.model = model
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                }
            }
        }

    }
}

#Preview {
    ContentView()
}
