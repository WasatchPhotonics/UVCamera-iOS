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
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate
{
    @IBOutlet weak var imageViewProcessed: UIImageView!
    
    var state : State?
    
    let saveAll = true
    var timeStart = DispatchTime.now()

    var captureSessionWide = AVCaptureSession()
    var captureSessionNarrow = AVCaptureSession()

    var cameraWide: AVCaptureDevice?
    var cameraNarrow: AVCaptureDevice?
    
    var photoOutputWide: AVCapturePhotoOutput?
    var photoOutputNarrow: AVCapturePhotoOutput?
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    ////////////////////////////////////////////////////////////////////////////
    // ViewController delegate
    ////////////////////////////////////////////////////////////////////////////

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading CameraViewController")

        print("setup AVCaptureSessions")
        captureSessionNarrow.sessionPreset = AVCaptureSession.Preset.photo
        captureSessionWide.sessionPreset = AVCaptureSession.Preset.photo

        print("finding cameras")
        cameraWide = findCamera(AVCaptureDevice.DeviceType.builtInWideAngleCamera)
        cameraNarrow = findCamera(AVCaptureDevice.DeviceType.builtInTelephotoCamera)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("CameraViewController will appear")
        
        print("adding NFOV camera as input to captureSessionNarrow")
        do
        {
            let captureDeviceInput = try AVCaptureDeviceInput(device: cameraNarrow!)
            captureSessionNarrow.addInput(captureDeviceInput)
            photoOutputNarrow = AVCapturePhotoOutput()
            photoOutputNarrow?.setPreparedPhotoSettingsArray(
                [AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])],
                completionHandler: nil)
            captureSessionNarrow.addOutput(photoOutputNarrow!)
        }
        catch
        {
            print(error)
            return
        }
        
        print("adding WFOV camera as input to our captureSessionWide")
        do
        {
            let captureDeviceInput = try AVCaptureDeviceInput(device: cameraWide!)
            captureSessionWide.addInput(captureDeviceInput)
            photoOutputWide = AVCapturePhotoOutput()
            photoOutputWide?.setPreparedPhotoSettingsArray(
                [AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])],
                completionHandler: nil)
            captureSessionWide.addOutput(photoOutputWide!)
        }
        catch
        {
            print(error)
            return
        }

        print("adding preview layer from current captureSessionNarrow")
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSessionNarrow)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = self.view.frame
        
        // insert new preview layer at back (behind button and thumbs)
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)

        activateNarrow()
    }
    
    func doingNarrow() -> Bool
    {
        return captureSessionNarrow.isRunning
    }
    
    func activateWide()
    {
        if captureSessionNarrow.isRunning
        {
            captureSessionNarrow.stopRunning()
        }
        print("running captureSessionWide")
        captureSessionWide.startRunning()
    }
    
    func activateNarrow()
    {
        if captureSessionWide.isRunning
        {
            captureSessionWide.stopRunning()
        }
        print("running captureSessionNarrow")
        captureSessionNarrow.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        // stop any running captureSessions
        if self.doingNarrow()
        {
            captureSessionNarrow.stopRunning()
        }
        else
        {
            captureSessionWide.stopRunning()
        }

        // remove the preview layer (will re-add for selected camera on next visit)
        cameraPreviewLayer?.removeFromSuperlayer()
        cameraPreviewLayer = nil

        // remove the cameras from our captureSessions
        do
        {
            let captureDeviceInput = try AVCaptureDeviceInput(device: cameraNarrow!)
            captureSessionNarrow.removeInput(captureDeviceInput)
        }
        catch
        {
            print(error)
        }
        
        do
        {
            let captureDeviceInput = try AVCaptureDeviceInput(device: cameraWide!)
            captureSessionWide.removeInput(captureDeviceInput)
        }
        catch
        {
            print(error)
        }
    }

    func findCamera(_ deviceType: AVCaptureDevice.DeviceType) -> AVCaptureDevice?
    {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [deviceType],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.back)
        for device in deviceDiscoverySession.devices
        {
            print("found \(deviceType)")
            return device
        }
        print("unable to find \(deviceType)")
        return nil
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // AVCapturePhotoCaptureDelegate
    ////////////////////////////////////////////////////////////////////////////
    
    func save(_ image: UIImage, _ label: String, force: Bool=false)
    {
        if !(saveAll || force)
        {
            return
        }
                
        print("Saving \(label)...")
        
        // https://stackoverflow.com/a/40858152
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if let imageData = photo.fileDataRepresentation()
        {
            print("Outputted image of \(imageData)")
            if let image = UIImage(data: imageData)
            {
                // did we just finish taking the NFOV (first) or WFOV (second) photo?
                if (self.doingNarrow())
                {
                    // just finished taking the first (NFOV) image, upon click
                    // of the button
                    profile("take NFOV photo")
                    
                    // keep a copy for processing
                    state!.imageNarrow = image
                    
                    // take the WFOV photo (which receipt will trigger multi-camera processing)
                    resetClock()
                    activateWide()
                    takePhoto()
                    profile("take WFOV photo")
                }
                else
                {
                    // just received the WFOV (second) image
                    
                    // store a copy
                    state!.imageWide = image

                    // perform multi-camera processing
                    performProcessing()

                    // then reset back to NFOV preparatory to the next button-press
                    activateNarrow()
                }
            }
        }
    }
    
    func performProcessing()
    {
        let hr = "\n"
        
        print("processing")
        if let W = state!.imageWide
        {
            if let N = state!.imageNarrow
            {
                // Assuming LPF is on W, where:
                //   W = WFOV
                //   N = NFOV
                //   U = UV
                // U = N - W
                // T = tint(U)
                // display(T atop N)

                let tintColor = CIColor(red: 1.0, green: 0.0, blue: 0.0)
                
                imageViewProcessed.image = N

                // This seems non-sensical, but it does something.  By default,
                // the cropped WFOV was coming out rotated 90º CCW (top = west).
                // When I explicitly rotated it 90º CW here, it came out (top =
                // east).  So now I explicitly rotate it 0º, and the cropped
                // version retains (top = north).
                resetClock()
                print("\(hr)rotating WFOV")
                let Wr = W.rotate(radians: 0)!
                save(Wr, "rotated WFOV")
                profile("rotate WFOV")
                
                // no need to rotate NFOV?
                let Nr = N

                print("\(hr)cropping WFOV")
                if let Wc = Wr.crop(percent: 0.5)
                {
                    imageViewProcessed.image = Wc
                    save(Wc, "cropped WFOV")

                    resetClock()
                    print("\(hr)resizing NFOV")
                    if let Nc = Nr.resize(0.5)
                    {
                        imageViewProcessed.image = Nc
                        save(Nc, "resized NFOV")
                        profile("resize NFOV")
                        
                        resetClock()
                        print("\(hr)converting WFOV to mono")
                        if let Wn = Wc.mono()
                        {
                            print("\(hr)saving mono WFOV")
                            save(Wn, "grayscale WFOV")
                            profile("grayscale WFOV")
                            
                            resetClock()
                            print("\(hr)converting NFOV to mono")
                            if let Nn = Nc.mono()
                            {
                                print("\(hr)saving mono NFOV")
                                save(Nn, "grayscale NFOV")
                                imageViewProcessed.image = Nn
                                profile("grayscale NFOV")

                                resetClock()
                                print("\(hr)generating UV")
                                if let UV = Nn.diff(Wn)
                                {
                                    save(UV, "UV (NFOV - WFOV)")
                                    profile("generate UV")
                                    imageViewProcessed.image = UV

                                    resetClock()
                                    print("\(hr)tinting UV")
                                    if let T = UV.tint(tintColor)
                                    {
                                        save(T, "tinted UV")
                                        imageViewProcessed.image = T
                                        profile("tint UV")

                                        resetClock()
                                        print("\(hr)blending T atop N")
                                        if let blended = Nn.blend(T)
                                        {
                                            profile("blended UV")
                                            
                                            resetClock()
                                            imageViewProcessed.image = blended
                                            save(blended, "blended VIS + UV", force: true)
                                            profile("save final image")
                                        }
                                        else
                                        {
                                            print("final blend failed")
                                        }
                                    }
                                    else
                                    {
                                        print("tint failed")
                                    }
                                }
                                else
                                {
                                    print("Nn - Wn diff failed")
                                }
                            }
                            else
                            {
                                print("failed to convert NFOV to grayscale")
                            }
                        }
                        else
                        {
                            print("failed to convert WFOV to grayscale")
                        }
                    }
                    else
                    {
                        print("failed to resize NFOV")
                    }
                }
                else
                {
                    print("failed to crop WFOV")
                }
            }
            else
            {
                print("processing: no NFOV")
            }
        }
        else
        {
            print("processing: no WFOV")
        }
    }
    
    func resetClock()
    {
        timeStart = DispatchTime.now()
    }
    
    func profile(_ label: String)
    {
        let timeEnd = DispatchTime.now()
        let elapsedSec = Double(timeEnd.uptimeNanoseconds - timeStart.uptimeNanoseconds) / 1_000_000_000
        print(String(format: ">>> Profile: %-30@ : %.2f sec", label, elapsedSec))
        resetClock()
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer)
    {
        if let error = error
        {
            // we got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        }
        else
        {
            // This is annoying...don't do it
            // showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
            print("Image saved to album")
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // Callbacks
    ////////////////////////////////////////////////////////////////////////////

    @IBAction func cameraButton_TouchUpInside(_ sender: Any)
    {
        resetClock()
        takePhoto()
    }
    
    func takePhoto()
    {
        var photoOutput : AVCapturePhotoOutput? = nil
        if doingNarrow()
        {
            photoOutput = photoOutputNarrow
        }
        else
        {
            photoOutput = photoOutputWide
        }
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    ////////////////////////////////////////////////////////////////////////////
    // Methods
    ////////////////////////////////////////////////////////////////////////////
    
    func showAlertWith(title: String, message: String)
    {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
