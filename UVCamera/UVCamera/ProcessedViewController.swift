//
//  ProcessedViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 3/18/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit

class ProcessedViewController: UIViewController {

    var state : State?
    var context : CIContext?
    
    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.context = CIContext(options: nil)
        
        if let st = self.state
        {
            if let img18 = st.image18
            {
                if let img24 = st.image24
                {
                    let img18Mono = toMono(img18).rotate(radians: .pi/2)!.crop(percent: 0.5)
                    let img24Mono = toMono(img24).rotate(radians: 0 - .pi/2)!
                    let diff = img18Mono.diff(img24Mono)
                    
                    image.image = diff
                }
            }
        }
    }
    
    // https://stackoverflow.com/a/40182080/11615696
    // todo: make extension method
    func toMono(_ img: UIImage) -> UIImage
    {
        // options: CIPhotoEffectMono, CIPhotoEffectNoir, CIPhotoEffectTonal
        let currentFilter = CIFilter(name: "CIPhotoEffectMono")
        currentFilter!.setValue(CIImage(image: img), forKey: kCIInputImageKey)
        let output = currentFilter!.outputImage
        let cgimg = self.context!.createCGImage(output!,from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }
}

extension UIImage
{
    func crop(percent: CGFloat) -> UIImage
    {
        let size = CGSize(width: self.size.width * percent, height: self.size.height * percent)
        return self.crop(to: size)
    }
    
    // https://stackoverflow.com/a/38777678/11615696
    func crop(to: CGSize) -> UIImage
    {
        guard let cgimage = self.cgImage else { return self }
        
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        
        guard let newCgImage = contextImage.cgImage else { return self }
        
        let origSize: CGSize = contextImage.size
        
        print("Crop: from \(origSize) to \(to)")
 
        let posX: CGFloat = (origSize.width/2) - (to.width/2)
        let posY: CGFloat = (origSize.height/2) - (to.height/2)

        let rect: CGRect = CGRect(x: posX, y: posY, width: to.width, height: to.height)
        print("Crop: rect = x: \(posX), y: \(posY), width: \(to.width), height: \(to.height)")
        
        // Create bitmap image from context using the rect
        guard let imageRef: CGImage = newCgImage.cropping(to: rect) else { return self }
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        UIGraphicsBeginImageContextWithOptions(to, false, self.scale)
        cropped.draw(in: CGRect(x: 0, y: 0, width: to.width, height: to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized ?? self
    }
    
    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-CJBDCFBH
    func diff(_ rhs: UIImage) -> UIImage?
    {
        let cgi : CGImage = self.cgImage!
        
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(self.size)

        // Draw the starting image in the current context as background
        self.draw(at: CGPoint.zero)
        
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!

        context.setBlendMode(CGBlendMode.difference)

        // subtract the second image
        let r = CGRect(x: 0, y: 0, width: cgi.width, height: cgi.height)
        context.draw(rhs.cgImage!, in: r)
        
        // Save the context as a new UIImage
        let diff = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Return modified image
        return diff
    }
    
    // https://stackoverflow.com/a/47402811/11615696
    func rotate(radians: Float) -> UIImage?
    {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
    
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
