//
//  SwiftUIView.swift
//
//
//  Created by 鍾哲玄 on 2024/6/6.
//

import SwiftUI

public struct InstructionView: View {
    var instruction: FaceDetectionState

    public init(instruction: FaceDetectionState) {
        self.instruction = instruction
    }

    public var body: some View {
        // Fix: don't know why adding this code causes ui update problem
        Text(instruction.rawValue)
            .foregroundStyle(instruction == .faceFit ? Color(.greenExtraDark) : Color(.redDark))
            .font(.headline)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    InstructionView(instruction: .faceFit)
}
