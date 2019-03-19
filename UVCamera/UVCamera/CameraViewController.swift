//
//  CameraViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 3/18/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController
{
    var state : State?
    var cameraNum : Int = 0 // 1 = wide-angle = ƒ/1.8
                            // 2 = telephoto = ƒ/2.4
    
    var captureSession = AVCaptureSession()
    var cameraWide: AVCaptureDevice?
    var cameraNarrow: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading CameraViewController")
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
    }
    
    func setupCaptureSession()
    {
        print("setupCaptureSession: start")
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        print("setupCaptureSession: end")
    }
    
    func setupWideAngleCamera()
    {
        print("setupWideAngleCamera: start")
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let devices = deviceDiscoverySession.devices
        for device in devices
        {
            print("found wide-angle camera")
            cameraWide = device
        }
        if cameraWide == nil
        {
            print("unable to find wide-angle camera")
        }
        else
        {
            currentCamera = cameraWide
        }
        print("setupWideAngleCamera: end")
    }

    func setupNarrowAngleCamera()
    {
        print("setupNarrowAngleCamera: start")
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInTelephotoCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let devices = deviceDiscoverySession.devices
        for device in devices
        {
            print("found narrow-angle camera")
            cameraNarrow = device
        }
        if cameraNarrow == nil
        {
            print("unable to find narrow-angle camera")
        }
        else
        {
            currentCamera = cameraNarrow
        }
        print("setupNarrowAngleCamera: end")
    }

    func setupDevice()
    {
        print("setupDevice: start")
        setupWideAngleCamera()
        // setupNarrowAngleCamera()
        currentCamera = cameraWide
        print("setupDevice: end")
    }
    
    func setupInputOutput()
    {
        print("setupInputOutput: start")
        do
        {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
            photoOutput?.setPreparedPhotoSettingsArray(
                [AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])],
                completionHandler: nil)
        }
        catch
        {
            print(error)
        }
        print("setupInputOutput: end")
    }
    
    func setupPreviewLayer()
    {
        print("setupPreviewLayer: start")
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        print("setupPreviewLayer: end")
    }
    
    func startRunningCaptureSession()
    {
        print("startRunningCaptureSession: start")
        captureSession.startRunning()
        print("startRunningCaptureSession: end")
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("CameraViewController will appear")
        print("cameraNum = \(self.cameraNum)")
    }
}
