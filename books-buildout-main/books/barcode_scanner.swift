import UIKit
import SwiftUI
import AVFoundation
import Vision

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onBarcodeScanned: (String) -> Void
    
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                CameraPreview(onBarcodeScanned: onBarcodeScanned)
                    .ignoresSafeArea()
                
                // Overlay with scanning frame
                ScanningOverlay()
                
                // Instructions
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Text("Scan ISBN Barcode")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Position the barcode within the frame")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            requestCameraPermission()
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
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let onBarcodeScanned: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.onBarcodeScanned = onBarcodeScanned
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
    
    class Coordinator {
        let parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
    }
}

// MARK: - Camera Preview UIView
class CameraPreviewView: UIView {
    var onBarcodeScanned: ((String) -> Void)?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
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
    
    private func setupCamera() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            return
        }
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
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
        
        session.addInput(videoInput)
        
        // Add metadata output for barcode detection
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
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            self?.captureSession = nil
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.removeFromSuperlayer()
            self?.previewLayer = nil
        }
    }
}

// MARK: - Barcode Detection
extension CameraPreviewView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for metadataObject in metadataObjects {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                continue
            }
            
            // Validate that this looks like an ISBN
            let cleanedBarcode = stringValue.replacingOccurrences(of: "-", with: "")
            if isValidISBN(cleanedBarcode) {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Call the completion handler
                onBarcodeScanned?(cleanedBarcode)
                return
            }
        }
    }
    
    private func isValidISBN(_ code: String) -> Bool {
        // Basic ISBN validation - should be 10 or 13 digits
        let digitsOnly = code.filter { $0.isNumber }
        return digitsOnly.count == 10 || digitsOnly.count == 13
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
        print("Scanned: \(barcode)")
    }
}