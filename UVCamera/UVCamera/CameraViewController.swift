//
//  CameraViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 3/18/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit
import AVFoundation

/// @see https://www.youtube.com/watch?v=7TqXrMnfJy8&list=PLaXWdRaxFtVcIwNK3ylcG9K8P8xYNirLl&index=3
class CameraViewController: UIViewController
{
    var state : State?
    var cameraNum : Int = 0 // 1 = wide-angle = ƒ/1.8
                            // 2 = telephoto  = ƒ/2.4
    
    var captureSession = AVCaptureSession()
    var cameraWide: AVCaptureDevice?
    var cameraNarrow: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    ////////////////////////////////////////////////////////////////////////////
    // ViewController delegate
    ////////////////////////////////////////////////////////////////////////////

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading CameraViewController")

        print("setup AVCaptureSession")
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        print("finding cameras")
        findWideAngleCamera()
        findNarrowAngleCamera()
        
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("CameraViewController will appear")
        print("cameraNum = \(self.cameraNum)")
        if (cameraNum == 1)
        {
            print("using wide camera")
            currentCamera = cameraWide
        }
        else
        {
            print("using narrow camera")
            currentCamera = cameraNarrow
        }

        print("adding current camera as input to our captureSession")
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
            return
        }

        // could possibly create both layers, and simply move current to the front
        print("adding preview layer from current captureSession")
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)

        print("running captureSession")
        captureSession.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // stop the captureSession
        captureSession.stopRunning()
        
        // remove the preview layer (will re-add for selected camera on next visit)
        cameraPreviewLayer?.removeFromSuperlayer()
        cameraPreviewLayer = nil

        // remove the camera from our captureSession
        do
        {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.removeInput(captureDeviceInput)
        }
        catch
        {
            print(error)
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Methods
    ////////////////////////////////////////////////////////////////////////////

    func findWideAngleCamera()
    {
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
    }

    func findNarrowAngleCamera()
    {
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
    }
}
