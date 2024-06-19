//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/14.
//

import CoreImage

extension CIImage {
    func averageBrightness(completion: @escaping (Double) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let extent = self.extent
            let options = [CIContextOption.useSoftwareRenderer: false]
            let context = CIContext(options: options)
            let brightnessFilter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: self, kCIInputExtentKey: CIVector(cgRect: extent)])
            
            if let outputImage = brightnessFilter?.outputImage {
                var bitmap = [UInt8](repeating: 0, count: 4)
                context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
                let brightness = Double(bitmap[0]) // Extract brightness value from the bitmap
                DispatchQueue.main.async {
                    completion(brightness)
                }
            }
        }
    }
}
