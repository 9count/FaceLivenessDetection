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
import Combine
import VideoToolbox

final class _FaceDetectionViewController: UIViewController {
    var faceDetectionViewModel: FaceDetectionViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: UI related properties
    private var jetPreviewLayer: AVCaptureVideoPreviewLayer?
    private var jetView: PreviewMetalView!
    private var circleRect: CGRect = .init(x: 0, y: 0, width: 250, height: 250)
    
    // MARK: Custom queues
    private let sessionQueue = DispatchQueue(label: "com.FaceLivenessDetection.session")
    private let videoQueue = DispatchQueue(label: "com.FaceLivenessDetection.video")
    private let visionQueue = DispatchQueue(label: ".com.FaceLivenessDetection.vistion")
    
    // MARK: Capture session setup
    private var captureSession = AVCaptureSession()
    private var videoDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    // MARK: Video processing helpers
    private let videoDepthConverter = DepthToJETConverter()
    private let videoDepthMixer = VideoMixer()
    private let livenessPredictor = LivenessPredictor()
    private var videoPixelBuffer: CVPixelBuffer?
    
    // MARK: Initialization
    init(viewModel: FaceDetectionViewModel) {
        self.faceDetectionViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        drawCircleView()
        setupBindings()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
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
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupPreviewLayer()
        updateJetView()
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
    
    // MARK: Private funcs
    private func setupBindings() {
        faceDetectionViewModel.$hidePreviewLayer
            .receive(on: RunLoop.main)
            .sink { [weak self] shouldHide in
                self?.hidePreviewLayer(shouldHide)
            }
            .store(in: &cancellables)

        faceDetectionViewModel.$instruction
            .receive(on: RunLoop.main)
            .sink { [weak self] instructionState in
                self?.previewLayerStatus(state: instructionState)
            }
            .store(in: &cancellables)

        faceDetectionViewModel.captureImagePublisher
            .sink { _ in
                self.captureButtonPressed()
            }
            .store(in: &cancellables)
    }
    
    private func hidePreviewLayer(_ shouldHide: Bool) {
        DispatchQueue.main.async {
            self.jetPreviewLayer?.isHidden = shouldHide
        }
    }
    
    // MARK: Capture session configuration
    private func configureCaptureSession() {
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
    
    func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.jetPreviewLayer = previewLayer
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = jetView.bounds
        previewLayer.cornerRadius = jetView.bounds.width / 2
        previewLayer.borderColor = UIColor(resource: .redDark).cgColor
        previewLayer.borderWidth = 2
        jetView.layer.addSublayer(previewLayer)
    }
    
    func updateJetView() {
        jetView.layer.cornerRadius = circleRect.width / 2
        jetView.clipsToBounds = true
    }
    
    func previewLayerStatus(state: FaceDetectionState) {
        DispatchQueue.main.async {
            self.jetPreviewLayer?.borderColor = state == .faceFit ? UIColor(resource: .greenExtraDark).cgColor : UIColor(resource: .redDark).cgColor
        }
    }
    
    func drawCircleView() {
        jetView = PreviewMetalView(frame: circleRect, device: MTLCreateSystemDefaultDevice())
        jetView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(jetView)
        let screenWidth = view.bounds.width
        let rect = CGRect(x: 0, y: 0, width: screenWidth * 0.64, height: screenWidth * 0.8)
        self.circleRect = rect
        // Set constraints
        NSLayoutConstraint.activate([
            jetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            jetView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            jetView.widthAnchor.constraint(equalToConstant: circleRect.width),
            jetView.heightAnchor.constraint(equalToConstant: circleRect.height)
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
        self.videoPixelBuffer = videoPixelBuffer
        let ciImage = CIImage(cvPixelBuffer: videoPixelBuffer)
        
        ciImage.averageBrightness { brightness in
            if brightness < 50 {
                DispatchQueue.main.async {
                    self.faceDetectionViewModel.lowLightEnvironment = true
                }
            }
        }

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                for face in results {
                    self?.analyzeFaceOrientation(face)
                }
            } else {
                DispatchQueue.main.async {
                    self?.faceDetectionViewModel.instruction = .noFace
                }
            }
        }
        let handler = VNImageRequestHandler(cvPixelBuffer: videoPixelBuffer, options: [:])
        
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

        self.jetView.pixelBuffer = jetPixelBuffer

        try? handler.perform([faceLandmarksRequest])
    }
    
    func analyzeFaceOrientation(_ face: VNFaceObservation) {
        let yaw = face.yaw?.doubleValue ?? 0.0
        let roll = face.roll?.doubleValue ?? 0.0
        let faceBoundingBox = face.boundingBox
        let faceArea = faceBoundingBox.width * faceBoundingBox.height

        var instruction: FaceDetectionState
        if faceArea < 0.15 {
            instruction = .faceTooFar
        } else if faceArea > 0.25 {
            instruction = .faceTooClose
        } else if abs(yaw) > 0.2 {
            if yaw > 0 {
                instruction = .faceRight
            } else {
                instruction = .faceLeft
            }
        } else {
            instruction = .faceFit
        }

        guard instruction != faceDetectionViewModel.instruction else { return }
        DispatchQueue.main.async {
            self.faceDetectionViewModel.instruction = instruction
        }
    }

    func captureButtonPressed() {
        guard let jetPixelBuffer = jetView.pixelBuffer else {
            logger.debug("No pixel buffer to capture")
            return
        }
        guard let videoPixelBuffer else { return }
        guard 
            let depthUiImage = UIImage(pixelBuffer: jetPixelBuffer),
            let capturedImage = UIImage(pixelBuffer: videoPixelBuffer)
        else { return }
        
        do {
            try self.livenessPredictor.makePrediction(for: depthUiImage) { [weak self] liveness, confidence in
                DispatchQueue.main.async {
                    var dataModel = LivenessDataModel(liveness: liveness, confidence: confidence, depthImage: depthUiImage, capturedImage: capturedImage)
                    self?.faceDetectionViewModel.predictionResult = dataModel
                }
            }
        } catch {
            logger.debug("predictor failure")
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
