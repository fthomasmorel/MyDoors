//
//  QRCodeReaderViewController.swift
//  Smartime
//
//  Created by Ricardo Pereira on 13/05/2015.
//  Copyright (c) 2015 Ricardo Pereira. All rights reserved.
//

import UIKit
import AVFoundation

public typealias ResultCallback = (QRCodeReaderViewController, String) -> ()
public typealias ErrorCallback = (QRCodeReaderViewController, NSError) -> ()
public typealias CancelCallback = (QRCodeReaderViewController) -> ()

enum QRCodeReaderViewControllerErrorCodes: Int {
    case UnavailableMetadataObjectType = 1
}

public class QRCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    private let metadataObjectTypes: [String]
    
    public var resultCallback: ResultCallback?
    public var errorCallback: ErrorCallback?
    public var cancelCallback: CancelCallback?
    
    private var avSession: AVCaptureSession?
    private var avDevice: AVCaptureDevice?
    private var avVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var lastCapturedString: String?
    
    // Constants
    private let fTorchLevel: Float = 0.25
    private let torchLevel = 0.25
    private let torchActivationDelay = 0.25
    private let errorDomain = "eu.ricardopereira.QRCodeReaderViewController"
    
    public convenience init() {
        self.init(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
    }
    
    public init(metadataObjectTypes: [String]) {
        self.metadataObjectTypes = metadataObjectTypes
        super.init(nibName: nil, bundle: nil)
        self.title = "QR Code"
    }
    
    public required init(coder aDecoder: NSCoder) {
        self.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        super.init(coder: aDecoder)!
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Config
        self.view.backgroundColor = UIColor.black
        
        // Gestures
        let torchGesture = UILongPressGestureRecognizer(target: self, action: Selector("handleTorchRecognizerTap:"))
        torchGesture.minimumPressDuration = torchLevel
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeDown:")
        swipeDownGesture.direction = .down
        
        self.view.addGestureRecognizer(torchGesture)
        self.view.addGestureRecognizer(swipeDownGesture)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = cancelCallback {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: Selector("cancelItemSelected:"))
        } else {
            self.navigationItem.leftBarButtonItem = nil
            
        }
        
        lastCapturedString = nil
        
        if errorCallback == nil, let _ = cancelCallback {
            errorCallback = { error in
                if let performCancel = self.cancelCallback {
                    self.avSession?.stopRunning()
                    performCancel(self)
                }
            }
        }
        
        self.avSession = AVCaptureSession()
        
        avVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: avSession);
        avVideoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill;
        avVideoPreviewLayer?.frame = self.view.bounds;
        
        DispatchQueue.global(qos: .background).async {
            self.avDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            
            if let session = self.avSession, let device = self.avDevice {
                // AVCaptureDevice
                try! device.lockForConfiguration()
                if device.isLowLightBoostSupported {
                    device.automaticallyEnablesLowLightBoostWhenAvailable = true
                    device.unlockForConfiguration()
                }
                
                session.beginConfiguration()
                
                var input = try! AVCaptureDeviceInput(device: device)
                
//                if let e = error {
//                    print("QRCodeReaderViewController: Error getting input device: \(e)")
//                    session.commitConfiguration()
//                    
//                    if let performError = self.errorCallback {
//                        DispatchQueue.main.async {
//                            session.stopRunning()
//                            performError(self, e)
//                        }
//                    }
//                    return
//                }
                
                session.addInput(input)
                
                let output = AVCaptureMetadataOutput()
                
                session.addOutput(output)
                
                for type in self.metadataObjectTypes {
                    // FIXME: Forced unwrap
                    if !(output.availableMetadataObjectTypes as! [String]).contains(type) {
                        if let performError = self.errorCallback {
                            DispatchQueue.main.async {
                                session.stopRunning()
                                performError(self, NSError(domain: self.errorDomain, code: QRCodeReaderViewControllerErrorCodes.UnavailableMetadataObjectType.rawValue, userInfo: [NSLocalizedDescriptionKey : "Unable to scan object of type \(type)"]))
                            }
                        }
                        return
                    }
                }
                
                output.metadataObjectTypes = self.metadataObjectTypes
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                session.commitConfiguration()
                
                DispatchQueue.main.async {
                    if let videoLayer = self.avVideoPreviewLayer, let conn = videoLayer.connection {
                        if conn.isVideoOrientationSupported {
                            //conn.videoOrientation = videoOrientationFromDeviceOrientation(UIDevice.currentDevice().orientation);
                        }
                    }
                    session.startRunning()
                }
            }
            
        }
        
        self.view.layer.addSublayer(self.avVideoPreviewLayer!)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        avVideoPreviewLayer?.removeFromSuperlayer();
        avVideoPreviewLayer = nil;
        avSession = nil;
        avDevice = nil;
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avVideoPreviewLayer?.bounds = self.view.bounds;
        avVideoPreviewLayer?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY);
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // The device has already rotated, that's why this method is being called
        if let videoLayer = self.avVideoPreviewLayer, let conn = videoLayer.connection {
            if conn.isVideoOrientationSupported {
                conn.videoOrientation = self.videoOrientationFromDeviceOrientation(orientation: UIDevice.current.orientation);
            }
        }
    }
    
    private func videoOrientationFromDeviceOrientation(orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch (orientation) {
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeRight
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    
    // MARK: UI Actions
    
    func cancelItemSelected(sender: AnyObject) {
        avSession?.stopRunning();
        cancelCallback?(self);
    }
    
    func handleSwipeDown(sender: UIGestureRecognizer) {
        avSession?.stopRunning();
        cancelCallback?(self);
    }
    
    func handleTorchRecognizerTap(sender: UIGestureRecognizer) {
        switch(sender.state) {
        case UIGestureRecognizerState.began:
            turnTorchOn()
        case UIGestureRecognizerState.changed, UIGestureRecognizerState.possible:
            break
        case UIGestureRecognizerState.ended, UIGestureRecognizerState.cancelled, UIGestureRecognizerState.failed:
            turnTorchOff()
        default:
            break
        }
    }
    
    
    // MARK: Torch
    
    func turnTorchOn() {
        if let device = avDevice {
            try! device.lockForConfiguration()
            if device.hasTorch && device.isTorchAvailable && device.isTorchModeSupported(.on) {
                try! device.setTorchModeOnWithLevel(fTorchLevel)
                device.unlockForConfiguration()
            }
        }
    }
    
    func turnTorchOff() {
        if let device = avDevice {
            try! device.lockForConfiguration()
            if device.hasTorch && device.isTorchAvailable && device.isTorchModeSupported(.off){
                device.torchMode = .off
                device.unlockForConfiguration()
            }
        }
    }
    
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        var metadataStr: String?
        
        for metadata in metadataObjects {
            if self.metadataObjectTypes.contains(metadata.type) {
                metadataStr = metadata.stringValue;
                break
            }
        }
        
        if let result = metadataStr {
            if lastCapturedString != result {
                lastCapturedString = result
                avSession?.stopRunning()
                resultCallback?(self, result)
            }
        }
    }
    
}
