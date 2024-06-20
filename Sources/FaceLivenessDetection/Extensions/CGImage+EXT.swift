//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/5.
//

import CoreImage
import VideoToolbox

public extension CGImage {
    static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage
    }
}
