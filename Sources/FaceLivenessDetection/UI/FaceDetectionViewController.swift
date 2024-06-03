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
import VideoToolbox

final class _FaceDetectionViewController: UIViewController {
    var faceDetectionViewModel: FaceDetectionViewModel

    private var jetView: PreviewMetalView!
    var instructionLabel: UILabel!
    var circleRect: CGRect = .init(x: 0, y: 0, width: 250, height: 250)
    private var captureButton: UIButton!
    
    // MARK: CaptureSession setup
    private let sessionQueue = DispatchQueue(label: "com.FaceLivenessDetection.session")
    private let videoQueue = DispatchQueue(label: "com.FaceLivenessDetection.video")
    var captureSession = AVCaptureSession()
    var videoDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
    var videoDeviceInput: AVCaptureDeviceInput!
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    private let videoDepthConverter = DepthToJETConverter()
    private let videoDepthMixer = VideoMixer()
    private let livenessPredictor = LivenessPredictor()
    
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
        setupCaptureButton()

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
        super.viewDidLayoutSubviews()
//        setupPreviewLayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let interfaceOrientation = UIApplication.shared.statusBarOrientation

        sessionQueue.async {
            let videoOrientation = self.videoDataOutput.connection(with: .video)!.videoOrientation
            let videoDevicePosition = self.videoDeviceInput.device.position
            let rotation = PreviewMetalView.Rotation(with: interfaceOrientation,
                                                     videoOrientation: videoOrientation,
                                                     cameraPosition: videoDevicePosition)
            self.jetView.mirroring = (videoDevicePosition == .front)
            if let rotation = rotation {
                self.jetView.rotation = rotation
            }
            
            self.captureSession.startRunning()
        }
    }
    
    // MARK: Capture session configuration
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
        self.videoDeviceInput = videoDeviceInput
        if captureSession.canAddInput(videoDeviceInput) {
            captureSession.addInput(videoDeviceInput)
        } else {
            logger.warning("input not added")
        }
        // add outputs to session
        if captureSession.canAddOutput(depthDataOutput) {
            captureSession.addOutput(depthDataOutput)
            depthDataOutput.isFilteringEnabled = true
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
            } else {
                logger.warning("depthDataOutput connection error")
            }
        }
    
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            
            logger.info("output setted success")
        } else {
            logger.warning("fail to setup output")
        }
        // choose 640 x 480 for lower resolution but lower latency than .photo
        captureSession.sessionPreset = .vga640x480
        
        // Search for highest resolution with half-point depth values
        let depthFormats = videoDevice.activeFormat.supportedDepthDataFormats
        let filtered = depthFormats.filter { CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16 }
        let selectedFormat = filtered.max(by: { first, second in
            CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
        })
        
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeDepthDataFormat = selectedFormat
            videoDevice.unlockForConfiguration()
        } catch {
            logger.warning("\(error.localizedDescription)")
            return
        }
        
        outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
        outputSynchronizer!.setDelegate(self, queue: videoQueue)
        captureSession.commitConfiguration()
    }
    
    // Make sure to be called at DidLayoutSubview
    func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = jetView.bounds
        previewLayer.cornerRadius = jetView.bounds.width / 2
        jetView.layer.addSublayer(previewLayer)
    }
    
    func drawCircleView() {
        jetView = PreviewMetalView(frame: circleRect, device: MTLCreateSystemDefaultDevice())
        jetView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(jetView)

        // Set constraints
        NSLayoutConstraint.activate([
            jetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            jetView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            jetView.widthAnchor.constraint(equalToConstant: circleRect.width),
            jetView.heightAnchor.constraint(equalToConstant: circleRect.height)
        ])

        // Configure the appearance to match the original UIView
        jetView.layer.cornerRadius = circleRect.width / 2
        jetView.layer.borderWidth = 2
        jetView.layer.borderColor = UIColor.gray.cgColor

        // Set the delegate to handle rendering if needed
//        jetView.delegate = self
        
        instructionLabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor(white: 0, alpha: 0.5)
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.boldSystemFont(ofSize: 18)
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: jetView.bottomAnchor, constant: 30),
            instructionLabel.centerXAnchor.constraint(equalTo: jetView.centerXAnchor)
        ])
    }
}

extension _FaceDetectionViewController: AVCaptureDataOutputSynchronizerDelegate {
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        guard 
            let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData,
            let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else {
            return
        }
        
        if syncedDepthData.depthDataWasDropped || syncedVideoData.sampleBufferWasDropped { return }
        
        let depthData = syncedDepthData.depthData
        let depthPixelBuffer = depthData.depthDataMap
        let sampleBuffer = syncedVideoData.sampleBuffer
        

        
        guard 
            let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        else { return }
        
        let request = VNDetectFaceRectanglesRequest { (request, error) in
            if let results = request.results as? [VNFaceObservation] {
                for face in results {
                    // Analyze face orientation
                    self.analyzeFaceOrientation(face)
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: videoPixelBuffer, options: [:])
        try? handler.perform([request])
        
        if !videoDepthConverter.isPrepared {
            var depthFormatDescription: CMFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: depthPixelBuffer, formatDescriptionOut: &depthFormatDescription)
            videoDepthConverter.prepare(with: depthFormatDescription!, outputRetainedBufferCountHint: 2)
        }
        
        guard let jetPixelBuffer = videoDepthConverter.render(pixelBuffer: depthPixelBuffer) else {
            logger.info("unable to process depth")
            return
        }
        
        if !videoDepthMixer.isPrepared {
            videoDepthMixer.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
        }
        
        guard let mixedBuffer = videoDepthMixer.mix(videoPixelBuffer: videoPixelBuffer, depthPixelBuffer: jetPixelBuffer) else { return }
        
        jetView.pixelBuffer = jetPixelBuffer

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

    private func setupCaptureButton() {
        captureButton = UIButton(type: .system)
        captureButton.setTitle("Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(captureButton)

        // Set constraints
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
    }
    
    @objc private func captureButtonPressed() {
        guard let jetPixelBuffer = jetView.pixelBuffer else {
            print("No pixel buffer to capture")
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: jetPixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            print("Image saved to photo album")
            do {
                try livenessPredictor.makePrediction(for: uiImage) { [weak self] liveness in
                    self?.faceDetectionViewModel.predictionResult = liveness
                }
            } catch {
                logger.debug("predictor failure")
            }
        } else {
            print("Failed to create CGImage from pixel buffer")
        }

//        savePixelBufferAsImage(pixelBuffer: jetPixelBuffer)
    }
    
    private func savePixelBufferAsImage(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let uiImage = UIImage(cgImage: cgImage)
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            print("Image saved to photo album")
        } else {
            print("Failed to create CGImage from pixel buffer")
        }
    }
}

extension CGImage {
    public static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage
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
