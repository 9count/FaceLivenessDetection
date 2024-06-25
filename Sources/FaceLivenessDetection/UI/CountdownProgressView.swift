//
//  SwiftUIView.swift
//
//
//  Created by 鍾哲玄 on 2024/6/25.
//

import SwiftUI

public struct CountdownProgressView: View {
    let duration: TimeInterval
    @State private var progress: Double = 0
    @State private var timer: Timer? = nil

    public init(_ duration: TimeInterval = 2) {
        self.duration = duration
    }

    public var body: some View {
        VStack {
            ProgressView(value: progress, total: 1)
                .progressViewStyle(CountDownProgressViewStyle())
                .onAppear {
                    startTimer()
                }
        }
        .foregroundStyle(.black)
    }

    func startTimer() {
        timer?.invalidate()
        print("Timer started")
        let increment = 0.1 / duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { tempTimer in
            self.progress += increment
            if self.progress >= 1 {
                self.progress = 1
                tempTimer.invalidate()
            }
        }
    }
}

struct CountDownProgressViewStyle: ProgressViewStyle {
    var strokeColor: Color = .white
    var strokeWidth: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .stroke(lineWidth: strokeWidth)
                .opacity(0.3)
                .foregroundColor(strokeColor)

            Circle()
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .foregroundColor(strokeColor)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: configuration.fractionCompleted)
        }
    }
}

#Preview {
    CountdownProgressView(2)
        .frame(width: 100, height: 100)
}
