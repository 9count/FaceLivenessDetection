//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/5.
//

import UIKit

extension UIImage {
    convenience init?(ciImage: CIImage, orientation: UIImage.Orientation) {
        let orientedCIImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))

        // Create a CIContext
        let context = CIContext(options: nil)

        // Render the CIImage to a CGImage
        guard let cgImage = context.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
            // Handle failure to create CGImage
            return nil
        }

        // Now you have the CGImage with the correct orientation applied
        // You can create a UIImage from it if needed
        self.init(cgImage: cgImage)
    }
    
    convenience init?(pixelBuffer: CVPixelBuffer) {
        if let cgImage = CGImage.create(pixelBuffer: pixelBuffer) {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}
