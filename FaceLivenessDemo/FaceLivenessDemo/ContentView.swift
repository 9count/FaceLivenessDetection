//
//  ContentView.swift
//  TestFaceLivenessDetection
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import SwiftUI
import FaceLivenessDetection

struct ContentView: View {
    var body: some View {
        FaceDetectionView()
            .frame(height: 500)
    }
}

#Preview {
    ContentView()
}
