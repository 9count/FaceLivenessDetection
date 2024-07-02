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

    func rotateUIImage(byDegrees degrees: CGFloat) -> UIImage? {
        let radians = degrees * CGFloat.pi / 180
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: radians)).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to the middle of the image so we will rotate and scale around the center.
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)

        // Rotate the image context
        context.rotate(by: radians)

        // Now, draw the rotated/scaled image into the context
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }
}
