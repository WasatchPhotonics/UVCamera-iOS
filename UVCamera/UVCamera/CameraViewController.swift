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
    
    func save(_ image: UIImage)
    {
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
                // Go ahead and save the photo to disk, although technically we
                // probably don't need this feature.
                if (self.doingNarrow())
                {
                    // imageViewThumb24.image = image
                    state!.imageNarrow = image
                    
                    // if we just received and processed a NFOV photo, immediately
                    // take a WFOV photo (which will trigger multi-camera processing)
                    activateWide()
                    takePhoto()
                }
                else
                {
                    // imageViewThumb18.image = image
                    state!.imageWide = image

                    // if we just took a WFOV photo, perform multi-camera processing,
                    // then reset back to NFOV preparatory to the next button-press
                    performProcessing()
                    activateNarrow()
                }
            }
        }
    }
    
    func performProcessing()
    {
        let hr = "\n-----------------------------\n"
        
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
                
                // print("\(hr)saving raw WFOV and NFOV")
                // save(W)
                // save(N)
                imageViewProcessed.image = N

                // This seems non-sensical, but it does something.  By default,
                // the cropped WFOV was coming out rotated 90º CCW (top = west).
                // When I explicitly rotated it 90º CW here, it came out (top =
                // east).  So now I explicitly rotate it 0º, and the cropped
                // version retains (top = north).
                print("\(hr)rotating WFOV")
                let Wr = W.rotate(radians: 0)! // .pi/2)!
                save(Wr) // good
                // let Wr = W
                
                // let Nr = N.rotate(radians: .pi/2, horizFlip: true)!
                // print("saving sized/rotated WFOV and NFOV")
                // save(Nr)
                // imageViewProcessed.image = Nr
                let Nr = N

                print("\(hr)cropping WFOV")
                if let Wc = Wr.crop(percent: 0.5)
                {
                    save(Wc) // good

                    print("\(hr)resizing NFOV")
                    if let Nc = Nr.resize(0.5)
                    {
                        imageViewProcessed.image = Nc
                        save(Nc) // good

                        print("\(hr)converting WFOV to normalized grayscale")
                        if let Wn = Wc.normalizeGrayscale()
                        {
                            print("\(hr)saving normalized grayscale WFOV")
                            save(Wn)  // BLOWS UP
                            
                            if true
                            {
                                print("\(hr)converting NFOV to normalized grayscale")
                                if let Nn = Nc.normalizeGrayscale()
                                {
                                    print("\(hr)saving normalized grayscale NFOV")
                                    save(Nn)
                                    imageViewProcessed.image = Nn

                                    if true
                                    {
                                        print("\(hr)generating UV")
                                        if let UV = Nn.diffGrayscale(Wn)
                                        {
                                            save(UV)
                                            imageViewProcessed.image = UV

                                            if true
                                            {
                                                print("\(hr)tinting UV")
                                                if let T = UV.tint(tintColor)
                                                {
                                                    save(T)
                                                    imageViewProcessed.image = T

                                                    print("\(hr)blending T atop N")
                                                    if let blended = Nn.blend(T)
                                                    {
                                                        imageViewProcessed.image = blended
                                                        save(blended)
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
                                        }
                                        else
                                        {
                                            print("Nn - Wn diff failed")
                                        }
                                    }
                                }
                                else
                                {
                                    print("failed to convert NFOV to grayscale")
                                }
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
