//
//  Util.swift
//  UVCamera
//
//  Created by Mark Zieg on 6/12/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import Foundation
import UIKit
import Accelerate

// https://spin.atomicobject.com/2016/10/20/ios-image-filters-in-swift/
class BlueFilter: CIFilter
{
    @objc dynamic var inputImage: CIImage?
    
    override public var outputImage: CIImage! {
        get {
            if let inputImage = self.inputImage {
                let args = [inputImage as AnyObject]
                return createCustomKernel().apply(extent: inputImage.extent, arguments: args)
            } else {
                return nil
            }
        }
    }
    
    // https://stackoverflow.com/a/42537079/11615696
    //
    // todo need to port this to Metal
    // see https://medium.com/@shu223/core-image-filters-with-metal-71afd6377f4
    // see https://developer.apple.com/metal/MetalCIKLReference6.pdf
    // see https://developer.apple.com/documentation/coreimage/cikernel
    func createCustomKernel() -> CIColorKernel {
        let kernelString =
            "kernel vec4 chromaKey( __sample s) {" +
                "vec4 newPixel = s.rgba;" +
                "newPixel[0] = 0.0;" +
                "newPixel[1] = 0.0;" +
                "return newPixel;" +
        "}"
        return CIColorKernel(source: kernelString)!
    }
}

class DropBlueFilter: CIFilter
{
    @objc dynamic var inputImage: CIImage?
    
    override public var outputImage: CIImage! {
        get {
            if let inputImage = self.inputImage {
                let args = [inputImage as AnyObject]
                return createCustomKernel().apply(extent: inputImage.extent, arguments: args)
            } else {
                return nil
            }
        }
    }
    
    // https://stackoverflow.com/a/42537079/11615696
    //
    // todo need to port this to Metal
    // see https://medium.com/@shu223/core-image-filters-with-metal-71afd6377f4
    // see https://developer.apple.com/metal/MetalCIKLReference6.pdf
    // see https://developer.apple.com/documentation/coreimage/cikernel
    func createCustomKernel() -> CIColorKernel {
        let kernelString =
            "kernel vec4 chromaKey( __sample s) {" +
                "vec4 newPixel = s.rgba;" +
                "newPixel[2] = 0.0;" +
                "return newPixel;" +
        "}"
        return CIColorKernel(source: kernelString)!
    }
}

// Please keep method names sorted alphabetically
//
// @todo dig through https://developer.apple.com/documentation/accelerate/vimage/adjusting_the_brightness_and_contrast_of_an_image
extension UIImage
{
    func adjustContrast(_ factor: Double) -> UIImage?
    {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CoreImage.CIImage(cgImage: cgImage)
        let parameters = [ "inputContrast": NSNumber(value: factor) ]
        let outputImage = ciImage.applyingFilter("CIColorControls", parameters: parameters)
        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }

    func adjustExposure(_ ev: Double) -> UIImage?
    {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CoreImage.CIImage(cgImage: cgImage)
        let parameters = [ "inputEV": NSNumber(value: ev) ]
        let outputImage = ciImage.applyingFilter("CIExposureAdjust", parameters: parameters)
        let context = CIContext(options: nil)
        let img = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: img)
    }
    
    func blend(_ img: UIImage, alpha: Float = 0.5, blendMode: CGBlendMode = CGBlendMode.normal) -> UIImage?
    {
        let size = self.size
        UIGraphicsBeginImageContext(size)
        
        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.draw(in: areaSize)
        
        img.draw(in: areaSize, blendMode: blendMode, alpha: CGFloat(alpha))
        
        let blended = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return blended
    }
    
    // https://stackoverflow.com/a/28907826/11615696
    func caption(text: String) -> UIImage
    {
        let textColor = UIColor.white
        let backgroundColor = UIColor.black
        let textFont = UIFont(name: "Helvetica Bold", size: 48)!
        let point = CGPoint(x: 10, y: 10)

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.backgroundColor: backgroundColor,
        ] as [NSAttributedString.Key : Any]
        self.draw(in: CGRect(origin: CGPoint.zero, size: self.size))

        let rect = CGRect(origin: point, size: self.size)
        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    // https://stackoverflow.com/a/43206409/11615696
    func copy() -> UIImage?
    {
        guard let cgImage = self.cgImage else { return nil }
        return UIImage(cgImage: cgImage,
                       scale: self.scale,
                       orientation: self.imageOrientation)
    }
    
    func crop(percent: CGFloat) -> UIImage?
    {
        let size = CGSize(width: self.size.width * percent, height: self.size.height * percent)
        return self.crop(to: size)
    }
    
    // https://stackoverflow.com/a/38777678/11615696
    func crop(to: CGSize) -> UIImage?
    {
        guard let cgi = self.cgImage else { return nil }
        let origSize: CGSize = self.size
        
        let posX: CGFloat = (origSize.width/2) - (to.width/2)
        let posY: CGFloat = (origSize.height/2) - (to.height/2)
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: to.width, height: to.height)
        
        guard let cgiCropped = cgi.cropping(to: rect) else { return nil }
        let imgCropped = UIImage(cgImage: cgiCropped)
        
        UIGraphicsBeginImageContextWithOptions(to, false, 1.0) // self.scale)
        imgCropped.draw(in: CGRect(x: 0, y: 0, width: to.width, height: to.height))
        let imgFinal = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let imgFinal = imgFinal
        {
            return imgFinal
        }

        print("Crop: error")
        return nil
    }
    
    func diff(_ rhs: UIImage) -> UIImage?
    {
        let size = self.size
        UIGraphicsBeginImageContext(size)
        
        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.draw(in: areaSize)
        
        rhs.draw(in: areaSize, blendMode: .difference, alpha: 1.0)
        
        let blended = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return blended
    }
    
    func dropBlue() -> UIImage?
    {
        guard let cgImage = self.cgImage else { return nil }
        let inputCIImage = CoreImage.CIImage(cgImage: cgImage)
        
        let filter = DropBlueFilter()
        filter.setValue(inputCIImage, forKey: kCIInputImageKey)
        
        // Get the filtered output image and return it
        let outputImage = filter.outputImage!

        let context = CIContext()
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
        {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    func invert() -> UIImage?
    {
        guard let cgImage = self.cgImage else { return nil }
        let ciImage = CoreImage.CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorInvert") else {
            print("invert: error on filter")
            return nil
        }
        filter.setDefaults()
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let context = CIContext(options: nil)
        guard let outputImage = filter.outputImage else {
            print("invert: error on output")
            return nil
        }
        guard let outputImageCopy = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("invert: error on copy")
            return nil
        }
        return UIImage(cgImage: outputImageCopy)
    }
    
    func justBlue() -> UIImage?
    {
        guard let cgImage = self.cgImage else { return nil }
        let inputCIImage = CoreImage.CIImage(cgImage: cgImage)
        
        let filter = BlueFilter()
        filter.setValue(inputCIImage, forKey: kCIInputImageKey)
        
        // Get the filtered output image and return it
        let outputImage = filter.outputImage!

        let context = CIContext()
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
        {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    // the "3" just means "3rd version of this function I've tried"
    // https://stackoverflow.com/a/55434232/11615696
    // generate a new image which is a monochrome (grayscale) version of the argument
    // see https://stackoverflow.com/a/40182080/11615696
    func mono() -> UIImage?
    {
        guard let currentCGImage = self.cgImage else { return nil }
        let currentCIImage = CIImage(cgImage: currentCGImage)

        // options: CIPhotoEffectMono, CIPhotoEffectNoir, CIPhotoEffectTonal
        // let filter = CIFilter(name: "CIPhotoEffectTonal")
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(currentCIImage, forKey: "inputImage")
        filter?.setValue(CIColor.white, forKey: "inputColor")
        filter?.setValue(1.0, forKey: "inputIntensity")

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
        {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    func normalize3() -> UIImage?
    {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let cgImage = cgImage else { return nil }
        
        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent),
                                          bitsPerPixel: UInt32(cgImage.bitsPerPixel),
                                          colorSpace: Unmanaged.passRetained(colorSpace),
                                          bitmapInfo: cgImage.bitmapInfo,
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: cgImage.renderingIntent)
        
        var source = vImage_Buffer()
        var result = vImageBuffer_InitWithCGImage(
            &source,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags))
        
        guard result == kvImageNoError else { return nil }
        
        defer { free(source.data) }
        
        var destination = vImage_Buffer()
        result = vImageBuffer_Init(
            &destination,
            vImagePixelCount(cgImage.height),
            vImagePixelCount(cgImage.width),
            32,
            vImage_Flags(kvImageNoFlags))
        guard result == kvImageNoError else { return nil }
        
        result = vImageContrastStretch_ARGB8888(&source, &destination, vImage_Flags(kvImageNoFlags))
        guard result == kvImageNoError else { return nil }
        
        defer { free(destination.data) }
        
        return vImageCreateCGImageFromBuffer(&destination, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil).map {
            UIImage(cgImage: $0.takeRetainedValue(), scale: scale, orientation: imageOrientation)
        }
    }
    
    // haven't managed to surpass normalize3 yet
    func normalize4_NOT_USED() -> UIImage?
    {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let cgImage = cgImage else { return nil }
        
        // https://stackoverflow.com/a/6314642/11615696
        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent),
                                          bitsPerPixel: UInt32(cgImage.bitsPerPixel),
                                          colorSpace: Unmanaged.passRetained(colorSpace),
                                          bitmapInfo: cgImage.bitmapInfo,
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: cgImage.renderingIntent)
        
        var source = vImage_Buffer()
        var result = vImageBuffer_InitWithCGImage(
            &source,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags))
        
        guard result == kvImageNoError else {
            print("normalize4: error on InitWithCGImage")
            return nil
        }
        
        defer { free(source.data) }
        
        var destination = vImage_Buffer()
        result = vImageBuffer_Init(
            &destination,
            vImagePixelCount(cgImage.height),
            vImagePixelCount(cgImage.width),
            32,
            vImage_Flags(kvImageNoFlags))
        
        guard result == kvImageNoError else {
            print("normalize4: error with Init")
            return nil
        }
        
        // result = vImageContrastStretch_ARGBFFFF(&source, &destination, nil, 256, 0, 255, vImage_Flags(kvImageLeaveAlphaUnchanged + kvImageDoNotTile))
        result = vImageContrastStretch_ARGB8888(&source, &destination, vImage_Flags(kvImageLeaveAlphaUnchanged + kvImageDoNotTile))
        guard result == kvImageNoError else {
            print("normalize4: error on vImageContrastStretch")
            return nil
        }
        
        defer { free(destination.data) }
        
        return vImageCreateCGImageFromBuffer(&destination, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil).map {
            UIImage(cgImage: $0.takeRetainedValue(), scale: scale, orientation: imageOrientation)
        }
    }
    
    func resize(_ percent: CGFloat) -> UIImage?
    {
        let height = size.height * percent
        let width = size.width * percent

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return img
    }
    
    // https://stackoverflow.com/a/47402811/11615696
    func rotate(radians: Float, horizFlip: Bool = false, vertFlip: Bool = false) -> UIImage?
    {
        var newSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        
        let x = CGFloat(vertFlip ? -1.0 : 1.0)
        let y = CGFloat(horizFlip ? -1.0 : 1.0)
        context.scaleBy(x: x, y: y)
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2,
                             y: -self.size.height/2,
                             width: self.size.width,
                             height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }

    // pass CIColor(red: 0.7, green: 0.7, blue: 0.7)
    // see https://www.hackingwithswift.com/example-code/media/how-to-desaturate-an-image-to-make-it-black-and-white
    func tint(_ ciColor: CIColor, _ intensity: CGFloat = 1.0) -> UIImage?
    {
        guard let currentCGImage = self.cgImage else { return nil }
        let currentCIImage = CIImage(cgImage: currentCGImage)
        
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(ciColor,        forKey: kCIInputImageKey)
        filter?.setValue(intensity,      forKey: "inputIntensity")
        filter?.setValue(currentCIImage, forKey: "inputImage")

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
        {
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    // Manual grayscale function which also normalizes whites and blacks, with
    // the goal of making images more "subtractable".  Doesn't matter if input
    // image was already in greyscale or not.  SLOW (~1.25sec)
    func normalize_slow_NOT_USED(intensify: Float = 1.0) -> UIImage?
    {
        if let cgi = self.cgImage
        {
            let width = cgi.width
            let height = cgi.height

            if let data = pixelValues()
            {
                let pixels = width * height
                var origGrayscale = [Float32](repeating: 0, count: pixels)

                // find min/max
                var hi : Float = -999
                var lo : Float =  999
                for i in 0 ..< pixels
                {
                    let offset = i * 4
     
                    let R = Float(data[offset+0])
                    let G = Float(data[offset+1])
                    let B = Float(data[offset+2])
                    let gray = (R + G + B) / 3.0
                    hi = max(gray, hi)
                    lo = min(gray, lo)
                    origGrayscale[i] = gray
                }

                print("norm: source intensity range (\(lo), hi \(hi))")
                if hi == lo
                {
                    print("ERROR: nothing to normalize (lo == hi)")
                    return nil
                }
     
                // iterate through data a second time, normalizing to the min/max
                var newData = [UInt8](repeating: 0, count: pixels * 4)
                for i in 0 ..< pixels
                {
                    let offset = i * 4
                    var norm = UInt16(((origGrayscale[i] - lo) / (hi - lo)) * 255.0 * intensify)
                    if norm > 255
                    {
                        norm = 255
                    }
                    let scaled = UInt8(norm)
                    newData[offset+0] = scaled
                    newData[offset+1] = scaled
                    newData[offset+2] = scaled
                }
                
                if let newCgi = Util.dataToImage(fromPixelValues: newData, width: width, height: height)
                {
                    return UIImage(cgImage: newCgi)  // need CGImageRelease(newCgi)?
                }
            }
        }
        print("norm: error")
        return nil
    }
    
    // generate an array of bytes representing the data in a CGImage
    // https://stackoverflow.com/a/34675717/11615696
    func pixelValues() -> [UInt8]?
    {
        if let cgImage = cgImage
        {
            let width = cgImage.width
            let height = cgImage.height
            let bitsPerComponent = cgImage.bitsPerComponent
            let bytesPerRow = cgImage.bytesPerRow
            let totalBytes = height * bytesPerRow
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = cgImage.bitmapInfo
     
            var intensities = [UInt8](repeating: 0, count: totalBytes)
            if let context = CGContext(data: &intensities,
                                       width: width,
                                       height: height,
                                       bitsPerComponent: bitsPerComponent,
                                       bytesPerRow: bytesPerRow,
                                       space: colorSpace,
                                       bitmapInfo: bitmapInfo.rawValue)
            {
                context.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
                return intensities
            }
        }
        return nil
    }

}

class Util
{
   // This is the opposite of pixelValues(), taking an array of bytes and
   // generating a CGImage.
   //
   // It takes an array of bytes assumed to be in [R, G, B, alpha] order
   // (and ignores the alpha anyway, though this could be changed)
   //
   // notes:
   // - current impl adapted from https://forums.swift.org/t/creating-a-cgimage-from-color-array/18634
   // - consider https://stackoverflow.com/a/55839062/11615696
   // - we may be okay using PNG per https://stackoverflow.com/a/17475842/11615696
   static func dataToImage(fromPixelValues pixelValues: [UInt8]?, width: Int, height: Int) -> CGImage?
   {
       if let pixelValues = pixelValues
       {
           let bitsPerComponent = 8
           let bytesPerPixel = 4
           let bytesPerRow = bytesPerPixel * width
           let totalBytes = height * bytesPerRow

           if totalBytes != pixelValues.count
           {
               print("ERROR: totalBytes \(totalBytes) != array length \(pixelValues.count)")
               return nil
           }

           var sRGB = [UInt32](repeating: 0x0, count: width * height)
           for row in 0 ..< height
           {
               for col in 0 ..< width
               {
                   let index = row * width + col
                   let offset = 4 * index
                   sRGB[index] = 0xff000000 | (UInt32(pixelValues[offset + 0]) << 16) | (UInt32(pixelValues[offset + 1]) << 8) | UInt32(pixelValues[offset + 2])
               }
           }

           return sRGB.withUnsafeMutableBytes { (ptr) -> CGImage in
               return CGContext(
                   data: ptr.baseAddress,
                   width: width,
                   height: height,
                   bitsPerComponent: bitsPerComponent,
                   bytesPerRow: bytesPerRow,
                   space: CGColorSpace(name: CGColorSpace.sRGB)!,
                   bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue)!.makeImage()!
           }
       }
       return nil
   }

}

/*

class Util
{
}
 
extension UIImage
{
     
    // This is a "manual" diff between two images, since Apple doesn't seem to
    // have a true "subtract" blend mode:
    // https://developer.apple.com/documentation/coregraphics/cgblendmode
    //
    // Since we're only using the first component of each pixel, technically we
    // could have pixelValues only return one byte per pixel, and have dataToImage
    // only take one byte per pixel.
    public func diffGrayscale_NOT_USED(_ rhs: UIImage) -> UIImage?
    {
        let cgiA = self.cgImage!
        let cgiB = rhs.cgImage!
     
        let widthA = cgiA.width
        let heightA = cgiA.height

        let widthB = cgiB.width
        let heightB = cgiB.height
     
        if let dataA = pixelValues()
        {
            if let dataB = rhs.pixelValues()
            {
                let lenA = dataA.count
                let lenB = dataB.count
     
                if lenA != lenB || widthA != widthB || heightA != heightB
                {
                    print("ERROR: diffGrayscale requires same length, width and height")
                    return nil
                }

                var newData = [UInt8](repeating: 0, count: lenA)
                let pixels = widthA * heightA
                for i in 0 ..< pixels
                {
                    let offset = i * 4
     
                    // assume that R, G and B are identical, so just grab Red (convert to signed for subtraction)
                    let delta = (UInt8)(abs(Int16(dataA[offset]) - Int16(dataB[offset])))
     
                    newData[offset  ] = delta
                    newData[offset+1] = delta
                    newData[offset+2] = delta
                }
     
                if let newCgi = Util.dataToImage(fromPixelValues: newData, width: widthA, height: heightA)
                {
                    return UIImage(cgImage: newCgi) // needs CGImageRelease(newCgi)?
                }
            }
        }
        print("normalize: error")
        return nil
    }

    // Manual grayscale function which also normalizes whites and blacks, with
    // the goal of making images more "subtractable".  Doesn't matter if input
    // image was already in greyscale or not.  SLOW (~1.25sec)
    func normalizeGrayscale_NOT_USED() -> UIImage?
    {
        if let cgi = self.cgImage
        {
            let width = cgi.width
            let height = cgi.height

            if let data = pixelValues()
            {
                let pixels = width * height
                var origGrayscale = [Float32](repeating: 0, count: pixels)

                // find min/max
                var hi : Float = -999
                var lo : Float =  999
                for i in 0 ..< pixels
                {
                    let offset = i * 4
     
                    let R = Float(data[offset+0])
                    let G = Float(data[offset+1])
                    let B = Float(data[offset+2])
                    let gray = (R + G + B) / 3.0
                    hi = max(gray, hi)
                    lo = min(gray, lo)
                    origGrayscale[i] = gray
                }

                print("norm: source intensity range (\(lo), hi \(hi))")
                if hi == lo
                {
                    print("ERROR: nothing to normalize (lo == hi)")
                    return nil
                }
     
                // iterate through data a second time, normalizing to the min/max
                var newData = [UInt8](repeating: 0, count: pixels * 4)
                for i in 0 ..< pixels
                {
                    let offset = i * 4
                    let norm = (UInt8)(((origGrayscale[i] - lo) / (hi - lo)) * 255.0)

                    newData[offset+0] = norm
                    newData[offset+1] = norm
                    newData[offset+2] = norm
                }
     
                if let newCgi = Util.dataToImage(fromPixelValues: newData, width: width, height: height)
                {
                    return UIImage(cgImage: newCgi)  // need CGImageRelease(newCgi)?
                }
            }
        }
        print("norm: error")
        return nil
    }
    
     public func orientationToString_NOT_USED() -> String
     {
         switch(self.imageOrientation)
         {
             case .up: return "up"
             case .down: return "down"
             case .left: return "left"
             case .right: return "right"
             case .upMirrored: return "upMirrored"
             case .downMirrored: return "downMirrored"
             case .leftMirrored: return "leftMirrored"
             case .rightMirrored: return "rightMirrored"
         }
     }
     

     public func mirrorHorizontal_NOT_USED() -> UIImage?
     {
        return UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: .leftMirrored)
     }
     
     // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-CJBDCFBH
     public func diff_NOT_USED(_ rhs: UIImage) -> UIImage?
     {
        let cgi : CGImage = self.cgImage!
        
        // Create a context of the starting image size and set it as the current one
        UIGraphicsBeginImageContext(self.size)
        
        // Draw the starting image in the current context as background
        self.draw(at: CGPoint.zero)
        
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!
        
        // see https://developer.apple.com/documentation/coregraphics/cgblendmode
        context.setBlendMode(CGBlendMode.xor)
        
        // subtract the second image
        let r = CGRect(x: 0, y: 0, width: cgi.width, height: cgi.height)
        context.draw(rhs.cgImage!, in: r)
        
        // Save the context as a new UIImage
        let diff = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Return modified image
        return diff
    }
}
*/
