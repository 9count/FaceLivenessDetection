//
//  FaceDetectionViewController.swift
//  
//
//  Created by 鍾哲玄 on 2024/5/30.
//

import UIKit
import SwiftUI
import AVFoundation
import os
import Vision

final class _FaceDetectionViewController: UIViewController {
    var faceDetectionViewModel: FaceDetectionViewModel
    private var circleView = UIView()
    var instructionLabel: UILabel!
    var circleRect: CGRect = .init(x: 0, y: 0, width: 250, height: 250)
    
    // MARK: CaptureSession setup
    private let sessionQueue = DispatchQueue(label: "com.FaceLivenessDetection.session")
    private let videoQueue = DispatchQueue(label: "com.FaceLivenessDetection.video")
    var captureSession = AVCaptureSession()
    var videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    init(viewModel: FaceDetectionViewModel) {
        self.faceDetectionViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawCircleView()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            sessionQueue.suspend()
            
            AVCaptureDevice.requestAccess(for: .video) { status in
                self.sessionQueue.resume()
            }
        default:
            break
        }
        
        sessionQueue.async {
            self.configureCaptureSession()
            self.captureSession.startRunning()
        }
    }
    override func viewDidLayoutSubviews() {
        setupPreviewLayer()
    }
    
    func configureCaptureSession() {
        captureSession.beginConfiguration()
        // add input device to session
        guard 
            let videoDevice = self.videoDevice,
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice)
        else {
            logger.warning("no capture device input found")
            return
        }
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        } else {
            logger.warning("input not added")
        }
        // add output to session
//        if captureSession.canAddOutput(depthDataOutput) {
//            captureSession.addOutput(depthDataOutput)
//            depthDataOutput.isFilteringEnabled = false
//            if let connection = depthDataOutput.connection(with: .depthData) {
//                connection.isEnabled = true
//            } else {
//                logger.warning("depthDataOutput connection error")
//            }
//        }
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            if let connection = videoDataOutput.connection(with: .video) {
                connection.isEnabled = true
            } else {
                logger.warning("video output connection error")
            }
            
            logger.info("output setted success")
        } else {
            logger.warning("fail to setup output")
        }
        captureSession.sessionPreset = .photo
        
        videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        captureSession.commitConfiguration()
    }
    
    // Make sure to be called at DidLayoutSubview
    func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = circleView.bounds
        previewLayer.cornerRadius = circleView.bounds.width / 2
        circleView.layer.addSublayer(previewLayer)
    }
    
    func drawCircleView() {
        view.addSubview(circleView)
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: circleRect.width),
            circleView.heightAnchor.constraint(equalToConstant: circleRect.height)
        ])
        
        circleView.layer.cornerRadius = circleRect.width / 2
        circleView.layer.borderWidth = 2
        circleView.layer.borderColor = UIColor.gray.cgColor
        
        instructionLabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor(white: 0, alpha: 0.5)
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.boldSystemFont(ofSize: 18)
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 30),
            instructionLabel.centerXAnchor.constraint(equalTo: circleView.centerXAnchor)
        ])
    }
}

extension _FaceDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            if let results = request.results as? [VNFaceObservation] {
                for face in results {
                    // Analyze face orientation
                    self.analyzeFaceOrientation(face)
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    // Analyze the face orientation and provide advice
    func analyzeFaceOrientation(_ face: VNFaceObservation) {
        let yaw = face.yaw?.doubleValue ?? 0.0
        let roll = face.roll?.doubleValue ?? 0.0
        let faceBoundingBox = face.boundingBox
        let faceArea = faceBoundingBox.width * faceBoundingBox.height
        var instructionString = ""
        logger.info("\(faceArea), face area")

        if faceArea < 0.1 {
            instructionString = "Move closer to the camera"
        } else if faceArea > 0.2 {
            instructionString = "Too close to the camera"
        } else if abs(yaw) > 0.2 {
            if yaw > 0 {
                instructionString = "Turn your head to the right"
            } else {
                instructionString = "Turn your head to the left"
            }
        } else {
            instructionString = "Face position is good"
        }
        DispatchQueue.main.async {
            self.faceDetectionViewModel.instruction = instructionString
        }
    }
}

struct FaceDetectionViewController: UIViewControllerRepresentable {
    @ObservedObject var faceDetectionViewModel: FaceDetectionViewModel
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = _FaceDetectionViewController(viewModel: faceDetectionViewModel)

        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    
    func makeCoordinator() -> () {
    }
}

fileprivate var logger = Logger.init(subsystem: "com.FaceLivenessDetection", category: "FaceDetectionViewController")
