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
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
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

    // you can set this to false to only use the "VIS" camera for
    // minimal workflow testing on a single-camera iPhone
    var useUVCamera = true
    
    var unfiltered : UIImage?
    var filtered : UIImage?
    
    var imagePicker = UIImagePickerController()
    
    // -------------------------------------------------------------------------
    // ViewController delegate
    // -------------------------------------------------------------------------

    // This fires EACH TIME seguing from Main Menu, but does NOT fire coming
    // "Back" from Settings
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

        // make the PIP image clickable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.imageTapped(gesture:)))
        imageViewPIP.addGestureRecognizer(tapGesture)
        imageViewPIP.isUserInteractionEnabled = true
    }
    
    // This fires EACH TIME seguing from Main Menu, but does NOT fire coming
    // "Back" from Settings
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        print("CameraViewController will appear")
        
        if cameraNarrow == nil || cameraWide == nil
        {
            showAlertWith(title: "Error", message: "UVCamera app requires dual rear-facing cameras")
            return
        }
        
        if captureSessionWide.inputs.count == 0
        {
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
        }
        else
        {
            print("not adding captureSessionWide input")
        }

        if useUVCamera && captureSessionNarrow.inputs.count == 0
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
        else
        {
            print("not adding captureSessionNarrow input")
        }
        
        setCameraPreviewFullScreen()

        activateWide()
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        print("CameraViewController disappearing")
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        print("preparing for transition")
        if let vc = segue.destination as? SettingsViewController
        {
            print("transitioning to SettingsViewController")
            vc.state = state
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
                    
                    // save raw images
                    save(state!.imageWide!, "unfiltered (raw)", force: true, caption: false)
                    save(state!.imageNarrow!, "filtered (raw)", force: true, caption: false)

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
            
            // This debug line can be interesting to see when save events actually
            // fire / complete.  In 1.x of this program (all processing in one
            // callback), the "saved" completions all fired at once (probably
            // sequentially?) the very end of processing.  In version 2.x when
            // we switched to serial tasks, they're a bit more real-time.
            //
            // print("Image saved to album")
        }
    }

    // -------------------------------------------------------------------------
    // UIImagePickerControllerDelegate
    // -------------------------------------------------------------------------

    // @see https://stackoverflow.com/a/51172065/11615696
    @objc(imagePickerController:didFinishPickingMediaWithInfo:) func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        print("imagePickerController.didFinishPickingImage")
        imagePicker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage

        // load WFOV (unfiltered) first
        if state!.imageWide == nil
        {
            print("storing picked image as WFOV (unfiltered)")
            state!.imageWide = image
            
            // prompt to load NFOV (filtered)
            print("re-presenting picker for NFOV")
            present(imagePicker, animated: true, completion: nil)
        }
        else if state!.imageNarrow == nil
        {
            print("storing picked image as NFOV (filtered)")
            state!.imageNarrow = image
            
            // kick-off processing
            print("processing picked images")
            performProcessing(reprocessing: true)

            // then reset back to WFOV preparatory to the next button-press
            print("resetting after processing picked images")
            activateWide()
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
    
    // @see https://stackoverflow.com/a/25514262/11615696
    @IBAction func loadClicked(_ sender: UIButton)
    {
        state!.imageNarrow = nil
        state!.imageWide = nil
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
        {
            print("Loading WFOV and NFOV from gallery")

            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
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
    
    func save(_ image: UIImage, _ label: String, force: Bool=false, caption: Bool=true)
    {
        if !force && !state!.saveComponents
        {
            return
        }
        
        print("Saving \(label)")
        
        // https://stackoverflow.com/a/40858152
        var imageSave = image
        if caption
        {
            if let captioned = image.caption(text: label)
            {
                imageSave = captioned
            }
        }
        UIImageWriteToSavedPhotosAlbum(imageSave, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // -------------------------------------------------------------------------
    // Gestures
    // -------------------------------------------------------------------------

    @objc func imageTapped(gesture: UIGestureRecognizer)
    {
        if (gesture.view as? UIImageView) != nil
        {
            print("PIP image tapped")
            
            // Open the Photos app
            UIApplication.shared.open(URL(string:"photos-redirect://")!)
        }
    }
    
    // -------------------------------------------------------------------------
    // Image Processing
    // -------------------------------------------------------------------------

    // This method is responsible for munging the two images into one processed
    // UV absorbance-enhanced photograph.
    //
    // It's broken into daisy-chained asynchronous calls because there seems to
    // be a limit on how much memory a single thread can consume, and when I
    // run the processing pipeline with full debugging enabled (saving an image
    // from every step in the processing chain), I get the error:
    //
    //      "Message from debugger: Terminated due to memory issue"
    //
    // I'm currently caching processing artifacts in the self object to easily
    // pass them between tasks; there's probably a cleaner way, but this works.
    //
    // This algorithm assumes the Long-Pass Filter (presumably around 410nm) is
    // on the NFOV camera, i.e.:
    //   WFOV = Unfiltered
    //   NFOV = Filtered
    //
    // @par Algorithm
    //
    // if we’re specifically looking to find UV absorbance, and as an
    // approximation we’re using shadows which are particularly or uniquely
    // dark in the (380, 410nm) to represent that, then we should be able to
    // bring those out using something like this:
    //
    // WHERE:
    //
    // \verbatim
    //     Suv  = Shadows exclusively in the range (380, 410nm) (not appearing in Svis)
    //     Svis = Shadows anywhere in VIS (410, 740nm)
    //     Sf   = Shadows in filtered camera (380, 410nm)
    //     Sgr  = Shadows in green, red region (500, 740nm)
    //     Sb   = Shadows in blue region (380, 500nm)
    //     Sb’  = Shadows in blue region, above filter (410, 500nm)
    // \endverbatim
    //
    // PROCESS:
    // - generate Sf: copy filtered orig; drop green, red channels; grayscale; invert; increase contrast (will show white for shadows in (380, 410); black for light in (380, 410))
    // - generate Sgr: copy unfiltered orig; drop blue channel; grayscale; invert; increase contrast (white for shadows in (500, 740); black for light in (500, 740))
    // - generate Sb: copy unfiltered orig; drop green, red channels; grayscale; invert; increase contrast (white for shadows in (380, 500); black for light in (380, 500))
    // - compute Sb’: Sf - Sb (white for shadows in (410, 500); black for light in (410, 500))
    // - compute Svis = Sgr + Sb’ (white for shadows in (410, 740); black for light in (410, 740))
    // - compute Suv = Sf - Svis (white for shadows exclusively in (380, 410))
    //
    // Then if we tint Suv and blend it atop the original unfiltered image, we
    // should be highlighting regions which are especially low in UV.

    func performProcessing(reprocessing: Bool = false)
    {
        let name = "performProcessing"
        print("starting processing")

        // ---------------------------------------------------------------------
        // Pre-process the two images to align them in size and contents so they
        // may be compared, subtracted etc
        // ---------------------------------------------------------------------

        if state!.imageWide == nil
        {
            print("\(name): no WFOV (unfiltered)")
            return
        }
        
        if state!.imageNarrow == nil
        {
            print("\(name): no NFOV (filtered)")
            return
        }
        
        unfiltered = registerUnfiltered()
        if unfiltered == nil
        {
            print("\(name): failed to generate unfiltered")
            return
        }

        filtered = registerFiltered()
        if filtered == nil
        {
            print("\(name): failed to generate filtered")
            return
        }

        // ---------------------------------------------------------------------
        // apply vertical shifts, either to live images or to reprocessed
        // ---------------------------------------------------------------------

        // These operations are done here, OUTSIDE of generateUnfiltered /
        // generateFiltered, because our stored test images were captured
        // unshifted, so we need to including the shifting in the post-load
        // processing.

        unfiltered = unfiltered!.cropVerticalShift(pixels: 0.5 * CGFloat(state!.processingSettings.cameraOffsetPixels)) // shift down
        if unfiltered == nil
        {
            print("\(name): failed to shift filtered")
            return
        }
        save(unfiltered!, "unfiltered (shifted)")

        filtered = filtered!.cropVerticalShift(pixels: -0.5 * CGFloat(state!.processingSettings.cameraOffsetPixels)) // shift up
        if filtered == nil
        {
            print("\(name): failed to shift unfiltered")
            return
        }
        save(filtered!, "filtered (shifted)")
        
        if filtered!.size != unfiltered!.size
        {
            print("\(name): shifted images have different sizes")
            return
        }

        // ---------------------------------------------------------------------
        // At this point we have mostly-identical wide (unfiltered) and narrow
        // (filtered) images with the same pixel dimensions, framing and
        // contents, just different sharpness (the WFOV/unfiltered is blurrier).
        // ---------------------------------------------------------------------
        
        // @see https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2
        DispatchQueue.global(qos: .userInitiated).async
        {
            [weak self] in
            guard let self = self else { return }

            var Sf = self.generateShadowsInFiltered()
            if Sf == nil
            {
                print("\(name): failed generateShadowsInFiltered")
                return
            }
            
            self.filtered = nil // no longer needed
            
            DispatchQueue.global(qos: .userInitiated).async
            {
                [weak self] in
                guard let self = self else { return }
   
                var Sgr = self.generateShadowsInGreenRed()
                if Sgr == nil
                {
                    print("\(name): failed generateShadowsInGreenRed")
                    return
                }
                
                DispatchQueue.global(qos: .userInitiated).async
                {
                    [weak self] in
                    guard let self = self else { return }

                    var Sb = self.generateShadowsInBlue()
                    if Sb == nil
                    {
                        print("\(name): failed generateShadowsInBlue")
                        return
                    }

                    DispatchQueue.global(qos: .userInitiated).async
                    {
                        [weak self] in
                        guard let self = self else { return }

                        var SbP = self.generateShadowsInBlueAboveFilter(shadowsInBlue: Sb!, shadowsInFiltered: Sf!)
                        if SbP == nil
                        {
                            print("\(name): failed generateShadowsInBlueAboveFilter")
                            return
                        }
                        
                        Sb = nil // no longer needed
                        
                        var Svis = self.generateShadowsInVIS(shadowsInGreenAndRed: Sgr!, shadowsInBlueAboveFilter: SbP!)
                        if Svis == nil
                        {
                            print("\(name): failed generateShadowsInVIS")
                            return
                        }
                        
                        Sgr = nil // no longer needed
                        SbP = nil // no longer needed
                        
                        var Suv = self.generateShadowsInUV(shadowsInFiltered: Sf!, shadowsInVIS: Svis!)
                        if Suv == nil
                        {
                            print("\(name): failed generateShadowsInUV")
                            return
                        }

                        Sf = nil // no longer needed
                        Svis = nil // no longer needed

                        DispatchQueue.global(qos: .userInitiated).async
                        {
                            [weak self] in
                            guard let self = self else { return }

                            // let tintColor = CIColor(red: 1.0, green: 0.0, blue: 0.0)
                            let SuvT = Suv!.tintFilter()
                            // let SuvT = Suv!.adjustWhitePoint(tintColor)
                            if SuvT == nil
                            {
                                print("\(name): failed tint")
                                return
                            }
                            
                            Suv = nil // no longer needed
                            self.save(SuvT!, "SuvT (tinted UV shadows)")
                            
                            let final = self.unfiltered!.blend(SuvT!, alpha: Float(self.state!.processingSettings.finalBlendAlpha))
                            if final == nil
                            {
                                print("\(name): failed final blend")
                                return
                            }
                            
                            self.unfiltered = nil // no longer needed
                            self.save(final!, "final (tinted UV over unfiltered)", force: true)
                            
                            // final dispatch is to GUI thread so we can update widget
                            DispatchQueue.main.async
                            {
                                [weak self] in
                                guard let self = self else { return }
                                
                                self.imageViewProcessed.image = final!
                            }
                        }
                    }
                }
            }
        }
    }

    // Scale the (filtered) NFOV raw image to a smaller image registered
    // with the (unfiltered) WFOV cropped photo.
    func registerFiltered() -> UIImage?
    {
        let name = "generateFiltered"
        
        let tmp = state!.imageNarrow!.resize(0.5)
        if tmp == nil
        {
            print("\(name) failed to resize NFOV (filtered)")
            return nil
        }

        save(tmp!, "filtered (resized NFOV)")
        return tmp
    }
    
    // Convert the (unfiltered) WFOV raw image to a cropped image registered
    // with the (filtered) NFOV camera.
    func registerUnfiltered(size: CGSize? = nil) -> UIImage?
    {
        let name = "generateUnfiltered"
        
        // This seems non-sensical, but it does something.  By default,
        // the cropped WFOV was coming out rotated 90º CCW (top = west).
        // When I explicitly rotated it 90º CW here, it came out (top =
        // east).  So now I explicitly rotate it 0º, and the cropped
        // version retains (top = north).
        var tmp = state!.imageWide!.rotate(radians: 0)
        if tmp == nil
        {
            print("\(name): failed wide rotation")
            return nil
        }
        save(tmp!, "unfiltered (derotated)")

        // The WFOV is, obviously, Wide Field of View, and therefore contains
        // much content that does not appear in the NFOV image.  As it happens,
        // presumably by Apple's design, it contains precisely twice as much
        // scene as the NFOV image, so to pre-register the images to "almost"
        // the same contents (other than the fact that the cameras are offset
        // rather than coaxial), all we have to do is crop the image down to 50%
        // of its original dimensions, retaining the original aspect ratio and
        // scaling.  (Just throw away a thick border around the center.)
        //
        // 2.0.9: actually, the WFOV is a tiny bit MORE than 2x the NFOV, so let's
        // shrink it down more than 50%, and then crop to precisely the NFOV
        // pixel dimensions.
        if true
        {
            tmp = tmp!.cropCentered(percent: 0.5)
            if tmp == nil
            {
                print("\(name) failed to crop WFOV")
                return nil
            }
            save(tmp!, "unfiltered (cropped centered)")
        }
        else
        {
            tmp = tmp!.resize(0.55) // NOT TESTED
            if tmp == nil
            {
                print("\(name) failed to scale WFOV")
                return nil
            }
            save(tmp!, "unfiltered (scaled WFOV)", force: true)
            
            if let sz = size
            {
                tmp = tmp!.cropCentered(to: sz)
                if tmp == nil
                {
                    print("\(name) failed to crop WFOV -> NFOV")
                    return nil
                }
                save(tmp!, "unfiltered (crop WFOV -> NFOV)", force: true)
            }
        }
        
        save(tmp!, "unfiltered (cropped/scaled WFOV)")
        return tmp
    }
    
    // @brief generate shadows in filtered camera (380, 410nm)
    //
    // Process: copy filtered orig; drop green, red channels; grayscale; invert; increase contrast
    //
    // @return white for shadows in (380, 410); black for light in (380, 410)
    func generateShadowsInFiltered() -> UIImage?
    {
        var tmp : UIImage? = nil
        let name = "generateShadowsInFiltered (380, 410)"

        // copy filtered orig
        tmp = filtered!.copy()
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
        save(tmp!, "\(name): justBlue")
        
        if true
        {
            // grayscale
            tmp = tmp!.mono()
            if tmp == nil
            {
                print("\(name): failed mono")
                return nil
            }
            save(tmp!, "\(name): mono")
        }
        
        tmp = tmp!.normalize() // normalize_slow()
        if tmp == nil
        {
            print("\(name): failed normalize")
            return nil
        }
        save(tmp!, "\(name): normalized")
        
        if state!.processingSettings.generateShadowsInFilteredExposureEnable
        {
            tmp = tmp!.adjustExposure(state!.processingSettings.generateShadowsInFilteredExposure)
            if tmp == nil
            {
                print("\(name): failed exposure")
                return nil
            }
            save(tmp!, "\(name): exposure")
        }

        // invert
        tmp = tmp!.invert()
        if tmp == nil
        {
            print("\(name): failed invert")
            return nil
        }
        save(tmp!, "\(name): inverted")
        
        if state!.processingSettings.generateShadowsInFilteredGammaPresetEnable
        {
            // darken gamma
            tmp = tmp!.applyGammaPreset(preset: state!.processingSettings.generateShadowsInFilteredGammaPresetEnum)
            if tmp == nil
            {
                print("\(name): failed darken gamma")
            }
            save(tmp!, "\(name): darken gamma")
        }

        if state!.processingSettings.generateShadowsInFilteredGammaAdjustEnable
        {
            // more darker gamma
            tmp = tmp!.adjustGamma(state!.processingSettings.generateShadowsInFilteredGammaAdjust)
            if tmp == nil
            {
                print("\(name): failed adjust gamma")
            }
            save(tmp!, "\(name): adjust gamma")
        }
        
        // contrast
        if state!.processingSettings.generateShadowsInFilteredContrastEnable
        {
            tmp = tmp!.adjustContrast(state!.processingSettings.generateShadowsInFilteredContrast)
            if tmp == nil
            {
                print("\(name): failed contrast")
                return nil
            }
            save(tmp!, "\(name): contrast")
        }
        
        // blur
        tmp = tmp!.blurBox()
        if tmp == nil
        {
            print("\(name): failed blur")
            return nil
        }
        save(tmp!, "\(name): blur")
    
        // posterize
        if state!.processingSettings.generateShadowsInFilteredPosterizeEnable
        {
            tmp = tmp!.posterize(NSNumber(value: state!.processingSettings.generateShadowsInFilteredPosterize))
            if tmp == nil
            {
                print("\(name): failed posterize")
                return nil
            }
            save(tmp!, "\(name): posterize")
        }

        // will show white for shadows in (380, 410); black for light in (380, 410)
        save(tmp!, "Sf (\(name))")
        return tmp
    }
    
    // @brief generate shadows in unfiltered green/red region (500, 740nm)
    //
    // process: copy unfiltered orig; drop blue channel; grayscale; invert; increase contrast
    //
    // @returns white for shadows in (500, 740); black for light in (500, 740)
    func generateShadowsInGreenRed() -> UIImage?
    {
        var tmp: UIImage? = nil
        let name = "generateShadowsInGreenRed (500-740)"
        
        // copy unfiltered orig
        tmp = unfiltered!.copy()
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
        save(tmp!, "\(name): dropBlue")

        // grayscale
        tmp = tmp!.mono()
        if tmp == nil
        {
            print("\(name): failed mono")
            return nil
        }
        save(tmp!, "\(name): mono")

        tmp = tmp!.normalize()
        if tmp == nil
        {
            print("\(name): failed normalize")
            return nil
        }
        save(tmp!, "\(name): normalized")

        if false
        {
            tmp = tmp!.adjustExposure(state!.processingSettings.generateShadowsInGreenRedExposure)
            if tmp == nil
            {
                print("\(name): failed exposure")
                return nil
            }
            save(tmp!, "\(name): exposure")
        }

        // invert
        tmp = tmp!.invert()
        if tmp == nil
        {
            print("\(name): failed invert")
            return nil
        }
        save(tmp!, "\(name): invert")

        if false
        {
            // contrast
            tmp = tmp!.adjustContrast(state!.processingSettings.generateShadowsInGreenRedContrast)
            if tmp == nil
            {
                print("\(name): failed contrast")
                return nil
            }
            save(tmp!, "\(name): contrast")
        }

        // return white for shadows in (500, 740); black for light in (500, 740)
        save(tmp!, "Sgr (\(name))")
        return tmp
    }

    // @brief Generate shadows in blue region (380, 500nm)
    //
    // process: copy unfiltered orig; drop green, red channels; grayscale; invert; increase contrast
    //
    // @returns white for shadows in (380, 500); black for light in (380, 500)
    func generateShadowsInBlue() -> UIImage?
    {
        var tmp: UIImage? = nil
        let name = "generateShadowsInBlue (380-500)"

        // copy unfiltered orig
        tmp = unfiltered!.copy()
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
        save(tmp!, "\(name): justBlue")

        // grayscale
        tmp = tmp!.mono()
        if tmp == nil
        {
            print("\(name): failed mono")
            return nil
        }
        save(tmp!, "\(name): mono")

        tmp = tmp!.normalize()
        if tmp == nil
        {
            print("\(name): failed normalize")
            return nil
        }
        save(tmp!, "\(name): normalized")
        
        if false
        {
            tmp = tmp!.adjustExposure(state!.processingSettings.generateShadowsInBlueExposure)
            if tmp == nil
            {
                print("\(name): failed exposure")
                return nil
            }
            save(tmp!, "\(name): exposure")
        }
        
        // invert
        tmp = tmp!.invert()
        if tmp == nil
        {
            print("\(name): failed invert")
            return nil
        }
        save(tmp!, "\(name): invert")

        if false
        {
            // contrast
            tmp = tmp!.adjustContrast(state!.processingSettings.generateShadowsInBlueExposure)
            if tmp == nil
            {
                print("\(name): failed contrast")
                return nil
            }
            save(tmp!, "\(name): contrast")
        }

        // white for shadows in (380, 500); black for light in (380, 500)
        save(tmp!, "Sb (\(name))")
        return tmp
    }

    // compute Sb’ (Sf - Sb)
    //
    // @returns white for shadows in (410, 500); black for light in (410, 500)
    func generateShadowsInBlueAboveFilter(shadowsInBlue: UIImage, shadowsInFiltered: UIImage) -> UIImage?
    {
        let name = "Shadows in Blue Above Filter (410-500)"
        
        // is this the right kind of subtraction?
        let tmp = shadowsInBlue.diff(shadowsInFiltered)
        if tmp == nil
        {
            print("\(name): failed diff")
            return nil
        }
        
        self.save(tmp!, "Sb' (\(name))")
        return tmp
    }

    // @brief compute Svis = Sgr + Sb’
    // @returns white for shadows in (410, 740); black for light in (410, 740)
    func generateShadowsInVIS(shadowsInGreenAndRed: UIImage, shadowsInBlueAboveFilter: UIImage) -> UIImage?
    {
        let name = "Shadows in VIS, 410-740"
        
        let tmp = shadowsInGreenAndRed.blend(shadowsInBlueAboveFilter, blendMode: CGBlendMode.screen)
        if tmp == nil
        {
            print("\(name): failed blend")
            return nil
        }
        
        self.save(tmp!, "Svis (\(name))")
        return tmp
    }
    
    // compute Suv = Sf - Svis (white for shadows exclusively in (380, 410)
    func generateShadowsInUV(shadowsInFiltered: UIImage, shadowsInVIS: UIImage) -> UIImage?
    {
        let name = "Shadows in UV, 380-410"
        
        var tmp = shadowsInFiltered.diff(shadowsInVIS)
        if tmp == nil
        {
            print("\(name): failed diff")
            return nil
        }
        self.save(tmp!, "\(name): diff")
        
        tmp = tmp!.applyGammaPreset(preset: state!.processingSettings.generateShadowsInUVPresetEnum)
        if tmp == nil
        {
            print("\(name): failed gamma contrast")
            return nil
        }
        self.save(tmp!, "\(name): gamma contrast")

        if false
        {
            // contrast
            tmp = tmp!.adjustContrast(1.5)
            if tmp == nil
            {
                print("\(name): failed contrast")
                return nil
            }
            save(tmp!, "\(name): contrast")
        
            tmp = tmp!.flatten2()
            if tmp == nil
            {
                print("\(name): failed flatten2")
                return nil
            }
            self.save(tmp!, "\(name): flatten2")
        }

        return tmp
    }
}
