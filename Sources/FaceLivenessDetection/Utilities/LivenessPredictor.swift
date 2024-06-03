//
//  File.swift
//  
//
//  Created by 鍾哲玄 on 2024/6/3.
//

import Vision
import UIKit

/// A convenience class that makes image classification predictions.
///
/// The Liveness Predictor creates and reuses an instance of a Core ML image classifier inside a ``VNCoreMLRequest``.
/// Each time it makes a prediction, the class:
/// - Creates a `VNImageRequestHandler` with an image
/// - Starts an image classification request for that image
/// - Converts the prediction results in a completion handler
/// - Updates the delegate's `predictions` property
/// - Tag: LivenessPredictor
public class LivenessPredictor {
    private static let livenessClassifier = createImageClassifier()

    private static func createImageClassifier() -> VNCoreMLModel {
        let defaultConfig = MLModelConfiguration()
        
        guard let imageClassifierWrapper = try? LivenessClassifierV1(configuration: defaultConfig) else {
            fatalError("App failed to create an image classifier model instance.")
        }
        
        guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierWrapper.model) else {
            fatalError("App failed to create a `VNCoreMLModel` instance.")
        }
        
        return imageClassifierVisionModel
    }
    
    public enum Liveness: String {
        case real = "Real"
        case fake = "Fake"
    }
    
    public typealias LivenessPredictionHandler = (_ liveness: Liveness) -> Void
    /// A dictionary of prediction handler functions, each keyed by its Vision request.
    private var predictionHandlers = [VNRequest: LivenessPredictionHandler]()
    
    /// Generates an image classification prediction for a photo.
    /// - Parameter photo: An image, typically of an object or a scene.
    /// - Tag: makePredictions
    public func makePrediction(for photo: UIImage, completionHandler: @escaping LivenessPredictionHandler) throws {
        let orientation = CGImagePropertyOrientation(photo.imageOrientation)
        guard let photoCGImage = photo.cgImage else {
            fatalError("Photo doesn't have underlying CGImage.")
        }
        
        let classificationRequest = createClassificationRequest()
        predictionHandlers[classificationRequest] = completionHandler
        
        let handler = VNImageRequestHandler(cgImage: photoCGImage, orientation: orientation)
        let requests = [classificationRequest]
        
        try handler.perform(requests)
    }
    
    /// Generates a new request instance that uses the Image Predictor's image classifier model.
    private func createClassificationRequest() -> VNImageBasedRequest {
        // Create an image classification request with an image classifier model.
        let classificationRequest = VNCoreMLRequest(model: Self.livenessClassifier, completionHandler: visionRequestHandler)
        
        classificationRequest.imageCropAndScaleOption = .centerCrop
        return classificationRequest
    }
    
    /// The completion handler method that Vision calls when it completes a request.
    /// - Parameters:
    ///   - request: A Vision request.
    ///   - error: An error if the request produced an error; otherwise `nil`.
    ///
    ///   The method checks for errors and validates the request's results.
    /// - Tag: visionRequestHandler
    private func visionRequestHandler(_ request: VNRequest, error: Error?) {
        guard let predictionHandler = predictionHandlers.removeValue(forKey: request) else {
            fatalError("Every request must have a prediction handler.")
        }
        
        if let error {
            print("Vision liveness classification error... \n\n\(error.localizedDescription)")
            return
        }
        
        if request.results == nil {
            print("Vision request had no results.")
            return
        }
        
        guard
            let observations = request.results as? [VNClassificationObservation],
            let result = observations.first
        else {
            print("VNRequest produced the wrong result type: \(type(of: request.results)).")
            return
        }
        
        guard let liveness = Liveness(rawValue: result.identifier) else {
            return
        }
        
        predictionHandler(liveness)
    }
}

extension CGImagePropertyOrientation {
    /// Converts an image orientation to a Core Graphics image property orientation.
    /// - Parameter orientation: A `UIImage.Orientation` instance.
    ///
    /// The two orientation types use different raw values.
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
            case .up: self = .up
            case .down: self = .down
            case .left: self = .left
            case .right: self = .right
            case .upMirrored: self = .upMirrored
            case .downMirrored: self = .downMirrored
            case .leftMirrored: self = .leftMirrored
            case .rightMirrored: self = .rightMirrored
            @unknown default: self = .up
        }
    }
}
