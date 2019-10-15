//
//  CameraViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 3/18/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//
// Version 1.0: initial requirements met

import UIKit
import AVFoundation

/// @see https://www.youtube.com/watch?v=7TqXrMnfJy8&list=PLaXWdRaxFtVcIwNK3ylcG9K8P8xYNirLl&index=3
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate
{
    @IBOutlet weak var imageViewFullScreen: UIImageView!
    @IBOutlet weak var imageViewPIP: UIImageView!
    var imageViewProcessed: UIImageView!
    
    var state : State?
    
    var timeStart = DispatchTime.now()

    var captureSessionWide = AVCaptureSession()
    var captureSessionNarrow = AVCaptureSession()

    var cameraWide: AVCaptureDevice?
    var cameraNarrow: AVCaptureDevice?
    
    var photoOutputWide: AVCapturePhotoOutput?
    var photoOutputNarrow: AVCapturePhotoOutput?
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    var previewFullScreen = true
    
    var useUVCamera = true
    
    let captionPhotos = true
    
    // -------------------------------------------------------------------------
    // ViewController delegate
    // -------------------------------------------------------------------------

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        print("loading CameraViewController")

        print("setup AVCaptureSessions")
        captureSessionWide.sessionPreset = AVCaptureSession.Preset.photo
        captureSessionNarrow.sessionPreset = AVCaptureSession.Preset.photo
        
        print("finding cameras")
        cameraWide = findCamera(AVCaptureDevice.DeviceType.builtInWideAngleCamera)
        cameraNarrow = findCamera(AVCaptureDevice.DeviceType.builtInTelephotoCamera)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("CameraViewController will appear")
        
        if cameraNarrow == nil || cameraWide == nil
        {
            showAlertWith(title: "Error", message: "UVCamera app requires dual rear-facing cameras")
            return
        }
        
        print("adding WFOV camera as input to captureSessionWide")
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

        if useUVCamera
        {
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
        }
        
        setCameraPreviewFullScreen()

        activateWide()
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

        deleteCameraPreview()
        
        if cameraNarrow == nil || cameraWide == nil
        {
            return
        }

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

    // -------------------------------------------------------------------------
    // AVCapturePhotoCaptureDelegate
    // -------------------------------------------------------------------------
    
    // after a photo has been taken with the NFOV or WFOV cameras, the photo
    // will be returned via this event
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if let imageData = photo.fileDataRepresentation()
        {
            print("Outputted image of \(imageData)")
            if let image = UIImage(data: imageData)
            {
                // did we just finish taking the WFOV (first) or NFOV (second) photo?
                if (self.doingWide())
                {
                    // just finished taking the first (WFOV) image, upon click
                    // of the button
                    profile("take WFOV photo")
                    state!.imageWide = image
                    resetClock()
                    
                    if useUVCamera
                    {
                        // initiate the NFOV photo (which receipt will trigger multi-camera processing)
                        activateNarrow()
                        takePhoto()
                        profile("take NFOV photo")
                    }
                }
                else
                {
                    // just received the NFOV (second) image
                    
                    // store a copy
                    state!.imageNarrow = image

                    // perform multi-camera processing
                    performProcessing()

                    // then reset back to WFOV preparatory to the next button-press
                    activateWide()
                }
            }
        }
    }

    // after saving a photo to the gallery, this event will provide the save
    // status
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

    // -------------------------------------------------------------------------
    // Callbacks
    // -------------------------------------------------------------------------

    @IBAction func cameraButton_TouchUpInside(_ sender: Any)
    {
        resetClock()
        takePhoto()
    }
    
    @IBAction func swapClicked(_ sender: UIButton)
    {
        // swap (x, y) and Size of cameraPreviewLayer and imageViewProcessed
        // set view.layer.zPosition = 1 // higher values on top, negatives okay
        
        deleteCameraPreview()
        if previewFullScreen
        {
            setCameraPreviewPIP()
        }
        else
        {
            setCameraPreviewFullScreen()
        }
    }

    // -------------------------------------------------------------------------
    //
    //                              Methods
    //
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    // used at startup to find the WFOV and NFOV cameras
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
    
    // -------------------------------------------------------------------------
    // Utility
    // -------------------------------------------------------------------------

    // display a modal message box
    func showAlertWith(title: String, message: String)
    {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    // when doing timing profiling, reset the timing clock
    func resetClock()
    {
        timeStart = DispatchTime.now()
    }
    
    // record the elapsed time since resetClock()
    func profile(_ label: String)
    {
        // let timeEnd = DispatchTime.now()
        // let elapsedSec = Double(timeEnd.uptimeNanoseconds - timeStart.uptimeNanoseconds) / 1_000_000_000
        // print(String(format: ">>> Profile: %-30@ : %.2f sec", label, elapsedSec))
        // resetClock()
    }
    
    // -------------------------------------------------------------------------
    // PIP vs FullScreen Views
    // -------------------------------------------------------------------------

    func setCameraPreviewFullScreen()
    {
        imageViewProcessed = imageViewPIP
        createPreviewLayer(view)
        previewFullScreen = true
    }
    
    func setCameraPreviewPIP()
    {
        imageViewProcessed = imageViewFullScreen
        createPreviewLayer(imageViewPIP)
        previewFullScreen = false
    }
    
    func createPreviewLayer(_ v: UIView)
    {
        deleteCameraPreview()
        
        imageViewPIP.image = nil
        imageViewFullScreen.image = nil
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSessionWide) // NOTE: WFOV is hard-coded here!
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        cameraPreviewLayer?.frame = v.bounds
        v.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    func deleteCameraPreview()
    {
        cameraPreviewLayer?.removeFromSuperlayer()
        cameraPreviewLayer = nil
    }

    // -------------------------------------------------------------------------
    // Switching between WFOV and NFOV
    // -------------------------------------------------------------------------

    func doingNarrow() -> Bool
    {
        return captureSessionNarrow.isRunning
    }
    
    func doingWide() -> Bool
    {
        return captureSessionWide.isRunning
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

    // -------------------------------------------------------------------------
    // Taking Photos
    // -------------------------------------------------------------------------

    // request a photo be taken from the currently selected camera
    func takePhoto()
    {
        let photoOutput = doingNarrow() ? photoOutputNarrow : photoOutputWide
        photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)

        // when the requested photo is complete, it will be delivered via photoOutput(_:didFinishProcessingPhoto)
    }
    
    func save(_ image: UIImage, _ label: String, force: Bool=false)
    {
        if !(force || state!.saveComponents)
        {
            return
        }
        
        print("Saving \(label)...")
        
        // https://stackoverflow.com/a/40858152
        UIImageWriteToSavedPhotosAlbum(captionPhotos ? image.caption(text:label) : image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // -------------------------------------------------------------------------
    // Image Processing
    // -------------------------------------------------------------------------

    func performProcessing()
    {
        let name = "performProcessing"

        // ---------------------------------------------------------------------
        // Pre-process the two images to align them in size and contents so they
        // may be compared, subtracted etc
        // ---------------------------------------------------------------------

        guard let W = state!.imageWide else
        {
            print("\(name): no WFOV")
            return
        }
        
        guard let N = state!.imageNarrow else
        {
            print("\(name): no NFOV")
            return
        }
        
        // Assuming LPF is on N, where:
        //   W = WFOV (Unfiltered)
        //   N = NFOV (Filtered)
                
        // This seems non-sensical, but it does something.  By default,
        // the cropped WFOV was coming out rotated 90º CCW (top = west).
        // When I explicitly rotated it 90º CW here, it came out (top =
        // east).  So now I explicitly rotate it 0º, and the cropped
        // version retains (top = north).
        guard let Wr = W.rotate(radians: 0) else
        {
            print("\(name): failed wide rotation")
            return
        }
        save(Wr, "rotated WFOV")
        
        // no need to rotate NFOV (don't ask me why)
        
        guard let unfiltered = Wr.crop(percent: 0.5) else
        {
            print("\(name) failed to crop WFOV")
            return
        }
        save(unfiltered, "cropped WFOV")

        guard let filtered = N.resize(0.5) else
        {
            print("\(name) failed to resize NFOV")
            return
        }
        save(filtered, "resized NFOV")

        // ---------------------------------------------------------------------
        // We now have mostly-identical wide (unfiltered) and
        // narrow (filtered) images with the same pixel dimensions,
        // framing and contents, just different sharpness (the
        // WFOV/unfiltered is blurrier).
        // ---------------------------------------------------------------------

        // if we’re specifically looking to find UV absorbance, and as an
        // approximation we’re using shadows which are particularly or uniquely
        // dark in the (380, 410nm) to represent that, then we should be able to
        // bring those out using something like this:
        //
        // WHERE:
        //     Suv  = Shadows exclusively in the range (380, 410nm) (not appearing in Svis)
        //     Svis = Shadows anywhere in VIS (410, 740nm)
        //     Sf   = Shadows in filtered camera (380, 410nm)
        //     Sgr  = Shadows in green, red region (500, 740nm)
        //     Sb   = Shadows in blue region (380, 500nm)
        //     Sb’  = Shadows in blue region, above filter (410, 500nm)
        //
        // PROCESS:
        // generate Sf: copy filtered orig; drop green, red channels; grayscale; invert; increase contrast (will show white for shadows in (380, 410); black for light in (380, 410))
        // generate Sgr: copy unfiltered orig; drop blue channel; grayscale; invert; increase contrast (white for shadows in (500, 740); black for light in (500, 740))
        // generate Sb: copy unfiltered orig; drop green, red channels; grayscale; invert; increase contrast (white for shadows in (380, 500); black for light in (380, 500))
        // compute Sb’: Sf - Sb (white for shadows in (410, 500); black for light in (410, 500))
        // compute Svis = Sgr + Sb’ (white for shadows in (410, 740); black for light in (410, 740))
        // compute Suv = Sf - Svis (white for shadows exclusively in (380, 410))
        //
        // Then if we tint Suv and blend it atop the original unfiltered image,
        // we should be highlighting regions which are especially low in UV.
        
        guard let Sf = generateShadowsInFiltered(filtered: filtered) else
        {
            print("\(name): failed generateShadowsInFiltered")
            return
        }
        save(Sf, "Sf (shadows in filtered)")
        
        guard let Sgr = generateShadowsInGreenRed(unfiltered: unfiltered) else
        {
            print("\(name): failed generateShadowsInGreenRed")
            return
        }
        save(Sgr, "Sgr (shadows in green/red)")
        
        guard let Sb = generateShadowsInBlue(unfiltered: unfiltered) else
        {
            print("\(name): failed generateShadowsInBlue")
            return
        }
        save(Sb, "Sb (shadows in blue)")
        
        guard let SbP = generateShadowsInBlueAboveFilter(shadowsFiltered: Sf, shadowsInBlue: Sb) else
        {
            print("\(name): failed generateShadowsInBlueAboveFilter")
            return
        }
        save(SbP, "Sb' (shadows in blue above filter)")
        
        guard let Svis = generateShadowsInVIS(shadowsInGreenRed: Sgr, shadowsInBlueAboveFilter: SbP) else
        {
            print("\(name): failed generateShadowsInVIS")
            return
        }
        save(Svis, "Svis (shadows in VIS)")
        
        guard let Suv = generateShadowsInUV(shadowsInFiltered: Sf, shadowsInVIS: Svis) else
        {
            print("\(name): failed generateShadowsInUV")
            return
        }
        save(Suv, "Suv (shadows in UV)")
        
        let tintColor = CIColor(red: 1.0, green: 0.0, blue: 0.0)
        guard let SuvT = Suv.tint(tintColor) else
        {
            print("\(name): failed tint")
            return
        }
        save(SuvT, "SuvT (tinted UV shadows)")
        
        guard let final = unfiltered.blend(SuvT) else
        {
            print("\(name): failed final blend")
            return
        }
        save(final, "final (tinted UV over unfiltered)")

        imageViewProcessed.image = final
    }
    
    // compute Suv = Sf - Svis (white for shadows exclusively in (380, 410)
    func generateShadowsInUV(shadowsInFiltered: UIImage, shadowsInVIS: UIImage) -> UIImage?
    {
        return shadowsInFiltered.diff(shadowsInVIS)
    }
    
    // @brief compute Svis = Sgr + Sb’
    // @returns white for shadows in (410, 740); black for light in (410, 740)
    func generateShadowsInVIS(shadowsInGreenRed: UIImage, shadowsInBlueAboveFilter: UIImage) -> UIImage?
    {
        return shadowsInGreenRed.blend(shadowsInBlueAboveFilter)
    }
    
    // compute Sb’ (Sf - Sb)
    //
    // @returns white for shadows in (410, 500); black for light in (410, 500)
    func generateShadowsInBlueAboveFilter(shadowsFiltered: UIImage, shadowsInBlue: UIImage) -> UIImage?
    {
        // is this the right kind of subtraction?
        return shadowsInBlue.diff(shadowsFiltered)
    }

    // @brief Generate shadows in blue region (380, 500nm)
    //
    // process: copy unfiltered orig; drop green, red channels; grayscale; invert; increase contrast
    //
    // @returns white for shadows in (380, 500); black for light in (380, 500)
    func generateShadowsInBlue(unfiltered: UIImage) -> UIImage?
    {
        var tmp: UIImage? = nil
        let name = "generateShadowsInBlue"
        
        // copy unfiltered orig
        tmp = unfiltered.copy()
        if tmp == nil
        {
            print("\(name): failed copy")
            return nil
        }
        
        // drop green, red channels
        tmp = tmp!.justBlue()
        if tmp == nil
        {
            print("\(name): failed justBlue")
            return nil
        }
        
        // grayscale
        tmp = tmp!.mono()
        if tmp == nil
        {
            print("\(name): failed mono")
            return nil
        }
        
        // invert
        tmp = tmp!.invert()
        if tmp == nil
        {
            print("\(name): failed invert")
            return nil
        }
        
        // contrast
        tmp = tmp!.adjustContrast(1.5)
        if tmp == nil
        {
            print("\(name): failed contrast")
        }
        
        // return white for shadows in (380, 500); black for light in (380, 500)
        return tmp
    }
    
    // @brief generate shadows in unfiltered green/red region (500, 740nm)
    //
    // process: copy unfiltered orig; drop blue channel; grayscale; invert; increase contrast
    //
    // @returns white for shadows in (500, 740); black for light in (500, 740)
    func generateShadowsInGreenRed(unfiltered: UIImage) -> UIImage?
    {
        var tmp: UIImage? = nil
        let name = "generateShadowsInGreenRed"
        
        // copy unfiltered orig
        tmp = unfiltered.copy()
        if tmp == nil
        {
            print("\(name): failed copy")
            return nil
        }
        
        // drop blue
        tmp = tmp!.dropBlue()
        if tmp == nil
        {
            print("\(name): failed dropBlue")
            return nil
        }
        
        // grayscale
        tmp = tmp!.mono()
        if tmp == nil
        {
            print("\(name): failed mono")
            return nil
        }
        
        // invert
        tmp = tmp!.invert()
        if tmp == nil
        {
            print("\(name): failed invert")
            return nil
        }
        
        // contrast
        tmp = tmp!.adjustContrast(1.5)
        if tmp == nil
        {
            print("\(name): failed contrast")
        }
        
        // return white for shadows in (500, 740); black for light in (500, 740)
        return tmp
    }

    // @brief generate shadows in filtered camera (380, 410nm)
    //
    // Process: copy filtered orig; drop green, red channels; grayscale; invert; increase contrast
    //
    // @return white for shadows in (380, 410); black for light in (380, 410)
    func generateShadowsInFiltered(filtered: UIImage) -> UIImage?
    {
        var tmp : UIImage? = nil
        let name = "generateShadowsInFiltered"

        // copy filtered orig
        tmp = filtered.copy()
        if tmp == nil
        {
            print("\(name): failed copy")
            return nil
        }
        
        // drop green, red channels
        tmp = tmp!.justBlue()
        if tmp == nil
        {
            print("\(name): failed justBlue")
            return nil
        }
        
        // grayscale
        tmp = tmp!.mono()
        if tmp == nil
        {
            print("\(name): failed mono")
            return nil
        }
        
        // invert
        tmp = tmp!.invert()
        if tmp == nil
        {
            print("\(name): failed invert")
            return nil
        }
        
        // contrast
        tmp = tmp!.adjustContrast(1.5)
        if tmp == nil
        {
            print("\(name): failed contrast")
        }
        
        // will show white for shadows in (380, 410); black for light in (380, 410)
        return tmp
    }
}
