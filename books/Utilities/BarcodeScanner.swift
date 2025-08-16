import UIKit
import SwiftUI
@preconcurrency import AVFoundation
import Vision

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onBarcodeScanned: (String) -> Void
    
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    @State private var isTorchOn = false
    @State private var scanningEnabled = true
    @State private var lastScanTime: Date?
    @State private var scanFeedback: String?
    @State private var cameraPreview: CameraPreviewView?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Boho gradient background for areas outside camera
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Camera preview
                CameraPreview(
                    onBarcodeScanned: handleBarcodeScanned,
                    isTorchOn: $isTorchOn,
                    scanningEnabled: $scanningEnabled,
                    onCameraReady: { preview in
                        cameraPreview = preview
                    }
                )
                    .ignoresSafeArea()
                
                // Overlay with scanning frame
                ScanningOverlay()
                
                // Instructions and controls
                VStack {
                    // Torch and focus controls
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Button(action: toggleTorch) {
                                Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel(isTorchOn ? "Turn off torch" : "Turn on torch")
                            
                            Button(action: focusCamera) {
                                Image(systemName: "camera.metering.center.weighted")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Focus camera")
                        }
                    }
                    .padding(.trailing)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text(scanningEnabled ? "Scan ISBN Barcode" : "Scanning...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(scanFeedback ?? "Position the barcode within the frame")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut(duration: 0.3), value: scanFeedback)
                    }
                    .padding()
                    .background(.black.opacity(0.6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { 
                        cleanup()
                        dismiss() 
                    }
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            requestCameraPermission()
        }
        .onDisappear {
            cleanup()
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { 
                permissionDenied = true
                dismiss()
            }
        } message: {
            Text("Please allow camera access in Settings to scan barcodes.")
        }
    }
    
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break // Already authorized
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        // Implement scan throttling
        let now = Date()
        if let lastScan = lastScanTime, now.timeIntervalSince(lastScan) < 2.0 {
            return // Too soon since last scan
        }
        
        lastScanTime = now
        scanningEnabled = false
        
        // Provide immediate feedback
        withAnimation {
            scanFeedback = "Barcode detected: \(barcode)"
        }
        
        // Haptic and audio feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Small delay for user feedback, then process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onBarcodeScanned(barcode)
        }
    }
    
    private func toggleTorch() {
        isTorchOn.toggle()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func focusCamera() {
        cameraPreview?.focusAtCenter()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Temporary feedback
        withAnimation {
            scanFeedback = "Focusing camera..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                if scanFeedback == "Focusing camera..." {
                    scanFeedback = nil
                }
            }
        }
    }
    
    private func cleanup() {
        // Turn off torch when leaving
        if isTorchOn {
            isTorchOn = false
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let onBarcodeScanned: (String) -> Void
    @Binding var isTorchOn: Bool
    @Binding var scanningEnabled: Bool
    let onCameraReady: (CameraPreviewView) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onBarcodeScanned = { @MainActor barcode in
            onBarcodeScanned(barcode)
        }
        view.scanningEnabled = scanningEnabled
        onCameraReady(view)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.updateTorch(isOn: isTorchOn)
        uiView.scanningEnabled = scanningEnabled
    }
    
    class Coordinator {
        let parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
    }
}

// MARK: - Camera Preview UIView
@MainActor
class CameraPreviewView: UIView {
    var onBarcodeScanned: (@MainActor (String) -> Void)?
    var scanningEnabled: Bool = true
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoDevice: AVCaptureDevice?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let visionQueue = DispatchQueue(label: "vision.queue")
    
    init() {
        super.init(frame: .zero)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            setupCamera()
        } else {
            stopSession()
        }
    }
    
    // MARK: - Public Methods
    nonisolated func updateTorch(isOn: Bool) {
        Task { @MainActor in
            guard let device = self.videoDevice, device.hasTorch else { return }
            
            sessionQueue.async {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = isOn ? .on : .off
                    device.unlockForConfiguration()
                } catch {
// print("❌ Failed to configure torch: \(error)")
                }
            }
        }
    }
    
    nonisolated func focusAtCenter() {
        Task { @MainActor in
            guard let device = self.videoDevice else { return }
            
            sessionQueue.async {
                do {
                    try device.lockForConfiguration()
                    
                    if device.isFocusModeSupported(.autoFocus) {
                        device.focusMode = .autoFocus
                        device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                    
                    if device.isExposureModeSupported(.autoExpose) {
                        device.exposureMode = .autoExpose
                        device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                    
                    device.unlockForConfiguration()
                } catch {
// print("❌ Failed to configure focus: \(error)")
                }
            }
        }
    }
    
    private func setupCamera() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            return
        }
        
        sessionQueue.async { [weak self] in
            Task { @MainActor in
                await self?.configureSession()
            }
        }
        
        // Add app lifecycle observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func configureSession() async {
        guard captureSession == nil else { return }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            return
        }
        
        self.videoDevice = videoDevice
        session.addInput(videoInput)
        
        // Configure video device for better scanning
        do {
            try videoDevice.lockForConfiguration()
            
            // Enable auto focus if available
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            
            // Enable auto exposure if available
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            
            // Configure HDR properly - disable auto adjustment first
            if videoDevice.activeFormat.isVideoHDRSupported {
                videoDevice.automaticallyAdjustsVideoHDREnabled = false
                videoDevice.isVideoHDREnabled = false // Disable HDR for faster processing
            }
            
            videoDevice.unlockForConfiguration()
        } catch {
// print("❌ Failed to configure video device: \(error)")
        }
        
        // Add video data output for Vision framework
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
        
        // Keep metadata output as fallback
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean13, .ean8, .upce, .code128, .code39, .code93, .interleaved2of5
            ]
        }
        
        session.commitConfiguration()
        
        // Create preview layer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.bounds
            
            self.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            self.captureSession = session
            
            // Start session
            self.sessionQueue.async {
                session.startRunning()
            }
        }
    }
    
    private func stopSession() {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Store current values to avoid actor isolation issues
        let currentSession = captureSession
        let currentDevice = videoDevice
        
        sessionQueue.async {
            // Turn off torch before stopping
            if let device = currentDevice, device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = .off
                    device.unlockForConfiguration()
                } catch {
// print("❌ Failed to turn off torch: \(error)")
                }
            }
            
            currentSession?.stopRunning()
        }
        
        // Clear properties on main actor
        Task { @MainActor in
            self.captureSession = nil
            self.videoDevice = nil
            self.videoOutput = nil
            self.previewLayer?.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
    // MARK: - App Lifecycle Management
    @objc private func appWillEnterForeground() {
        Task { @MainActor in
            guard let session = self.captureSession else { return }
            
            sessionQueue.async {
                session.startRunning()
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        Task { @MainActor in
            guard let session = self.captureSession else { return }
            let device = self.videoDevice
            
            sessionQueue.async {
                // Turn off torch when going to background
                if let device = device, device.hasTorch {
                    do {
                        try device.lockForConfiguration()
                        device.torchMode = .off
                        device.unlockForConfiguration()
                    } catch {
// print("❌ Failed to turn off torch: \(error)")
                    }
                }
                
                session.stopRunning()
            }
        }
    }
}

// MARK: - Vision Framework Integration
extension CameraPreviewView: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Process the pixel buffer directly without crossing actor boundaries
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard error == nil,
                  let results = request.results as? [VNBarcodeObservation] else {
                return
            }
            
            for result in results {
                guard let payloadString = result.payloadStringValue,
                      let self = self else { continue }
                
                let cleanedBarcode = payloadString.replacingOccurrences(of: "-", with: "")
                if self.isValidISBN(cleanedBarcode) {
                    Task { @MainActor in
                        guard self.scanningEnabled else { return }
                        self.onBarcodeScanned?(cleanedBarcode)
                    }
                    return
                }
            }
        }
        
        // Configure barcode types
        request.symbologies = [
            .ean13, .ean8, .upce, .code128, .code39, .code93, .i2of5
        ]
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
// print("❌ Vision barcode detection failed: \(error)")
        }
    }
    
}

// MARK: - Fallback Barcode Detection (AVCapture)
extension CameraPreviewView: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Process metadata objects directly without crossing actor boundaries
        for metadataObject in metadataObjects {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                continue
            }
            
            // Validate that this looks like an ISBN
            let cleanedBarcode = stringValue.replacingOccurrences(of: "-", with: "")
            if isValidISBN(cleanedBarcode) {
                Task { @MainActor in
                    guard self.scanningEnabled else { return }
                    self.onBarcodeScanned?(cleanedBarcode)
                }
                return
            }
        }
    }
    
    // MARK: - Enhanced ISBN Validation
    nonisolated internal func isValidISBN(_ code: String) -> Bool {
        let digitsOnly = code.filter { $0.isNumber }
        
        // Check length first
        guard digitsOnly.count == 10 || digitsOnly.count == 13 else {
            return false
        }
        
        if digitsOnly.count == 10 {
            return isValidISBN10(digitsOnly)
        } else {
            return isValidISBN13(digitsOnly)
        }
    }
    
    nonisolated internal func isValidISBN10(_ isbn: String) -> Bool {
        guard isbn.count == 10 else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            if index == 9 && char.uppercased() == "X" {
                // Last character can be 'X' (representing 10)
                sum += 10 * 1
            } else if let digit = char.wholeNumberValue {
                sum += digit * (10 - index)
            } else {
                return false
            }
        }
        
        return sum % 11 == 0
    }
    
    nonisolated internal func isValidISBN13(_ isbn: String) -> Bool {
        guard isbn.count == 13 else { return false }
        
        var sum = 0
        for (index, char) in isbn.enumerated() {
            guard let digit = char.wholeNumberValue else {
                return false
            }
            
            if index % 2 == 0 {
                sum += digit
            } else {
                sum += digit * 3
            }
        }
        
        return sum % 10 == 0
    }
}

// MARK: - Scanning Overlay
struct ScanningOverlay: View {
    @State private var isScanning = false
    
    var body: some View {
        ZStack {
            // Darkened background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Scanning frame
            VStack {
                Spacer()
                
                ZStack {
                    // Clear rectangle for scanning area
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .frame(width: 280, height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    // Animated scanning line
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 260, height: 2)
                        .offset(y: isScanning ? -60 : 60)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isScanning
                        )
                }
                
                Spacer()
            }
        }
        .onAppear {
            isScanning = true
        }
        .allowsHitTesting(false) // Allow touches to pass through
    }
}

#Preview {
    BarcodeScannerView { barcode in
// print("Scanned: \(barcode)")
    }
}
