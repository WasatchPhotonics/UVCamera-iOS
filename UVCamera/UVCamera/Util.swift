//
//  Util.swift
//  UVCamera
//
//  Created by Mark Zieg on 6/12/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import Foundation
import UIKit

class Util
{
    // generate a new image which is a monochrome (grayscale) version of the argument
    // todo: make extension method
    // see https://stackoverflow.com/a/40182080/11615696
    static func toMono(_ img: UIImage) -> UIImage
    {
        let context = CIContext(options: nil)
        
        // options: CIPhotoEffectMono, CIPhotoEffectNoir, CIPhotoEffectTonal
        let currentFilter = CIFilter(name: "CIPhotoEffectTonal")
        currentFilter!.setValue(CIImage(image: img), forKey: kCIInputImageKey)
        let output = currentFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }
    
    // generate an array of bytes representing the data in a CGImage
    // https://stackoverflow.com/a/34675717/11615696
    static func pixelValues(_ cgImage: CGImage?) -> [UInt8]?
    {
        if let cgImage = cgImage
        {
            print("pixelValues: starting")
            
            let width = cgImage.width
            print("pixelValues: width = \(width)")

            let height = cgImage.height
            print("pixelValues: height = \(height)")
            
            let bitsPerComponent = cgImage.bitsPerComponent
            print("pixelValues: bitsPerComponent = \(bitsPerComponent)")
            
            let bytesPerRow = cgImage.bytesPerRow
            print("pixelValues: bytesPerRow = \(bytesPerRow)")
            
            let impliedBytesPerPixel = Float(bytesPerRow) / Float(width)
            let rightSize = impliedBytesPerPixel == 4.0
            print("impliedBytesPerPixel = \(impliedBytesPerPixel) (right size \(rightSize))")
            
            let totalBytes = height * bytesPerRow
            print("pixelValues: totalBytes = \(totalBytes)")

            // this worked creating N/WFOV normalized grayscale with 0x281667b40 kCGColorSpaceICCBased; kCGColorSpaceModelRGB; sRGB IEC61966-2.1
            // failed with 0x281667a80 kCGColorSpaceDeviceRGB
            let colorSpace = CGColorSpaceCreateDeviceRGB() // cgImage.colorSpace
            print("colorSpace = \(String(describing: colorSpace))")

            let bitmapInfo = cgImage.bitmapInfo
            print("bitmapInfo = \(bitmapInfo)")

            print("allocating array of \(totalBytes) bytes")
            var intensities = [UInt8](repeating: 0, count: totalBytes)
            var result = [UInt8](repeating: 0, count: totalBytes)

            /*
             CGBitmapContextCreate: unsupported parameter combination:
               8 bits/component; integer;
               24 bits/pixel;
               RGB color space model; kCGImageAlphaNone;
               default byte order;
               6048 bytes/row.
             Valid parameters for RGB color space model are:
               16  bits per pixel, 5  bits per component, kCGImageAlphaNoneSkipFirst
               32  bits per pixel, 8  bits per component, kCGImageAlphaNoneSkipFirst
               32  bits per pixel, 8  bits per component, kCGImageAlphaNoneSkipLast         (CGImageAlphaInfo.NoneSkipFirst.rawValue)
               32  bits per pixel, 8  bits per component, kCGImageAlphaPremultipliedFirst
               32  bits per pixel, 8  bits per component, kCGImageAlphaPremultipliedLast
               32  bits per pixel, 10 bits per component, kCGImageAlphaNone|kCGImagePixelFormatRGBCIF10
               64  bits per pixel, 16 bits per component, kCGImageAlphaPremultipliedLast
               64  bits per pixel, 16 bits per component, kCGImageAlphaNoneSkipLast
               64  bits per pixel, 16 bits per component, kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents
               64  bits per pixel, 16 bits per component, kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents
               128 bits per pixel, 32 bits per component, kCGImageAlphaPremultipliedLast|kCGBitmapFloatComponents
               128 bits per pixel, 32 bits per component, kCGImageAlphaNoneSkipLast|kCGBitmapFloatComponents
            */

            print("pixelValues: instantiating CGContext")
            if let context = CGContext(data: &intensities,
                                       width: width,
                                       height: height,
                                       bitsPerComponent: bitsPerComponent,
                                       bytesPerRow: bytesPerRow,
                                       space: colorSpace,
                                       bitmapInfo: bitmapInfo.rawValue)
            {
                print("pixelValues: back")
                print("pixelValues: drawing")
                context.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height))) // EXC_BAD_ACCESS after "generating UV"

                // there are much faster ways to do this, and the copy itself might be unnecessary...trying to track down memory bug
                print("pixelValues: copying")
                for i in 0 ..< totalBytes
                {
                    result[i] = intensities[i]
                }
            }
            return result
        }
        print("pixelValues: error")
        return nil
    }
    
    // this is the opposite of pixelValues(), taking an array of bytes and generating a CGImage
    // notes:
    // - consider https://stackoverflow.com/a/55839062/11615696
    // - we may be okay using PNG per https://stackoverflow.com/a/17475842/11615696
    static func dataToImage(fromPixelValues pixelValues: [UInt8]?, width: Int, height: Int) -> CGImage?
    {
        // var imageRef: CGImage?
        
        if let pixelValues = pixelValues
        {
            let bitsPerComponent = 8
            let bytesPerPixel = 4
            // let bitsPerPixel = bytesPerPixel * bitsPerComponent
            let bytesPerRow = bytesPerPixel * width
            let totalBytes = height * bytesPerRow
            
            // let totalPixels = width * height
            if totalBytes != pixelValues.count
            {
                print("ERROR: totalBytes \(totalBytes) != array length \(pixelValues.count)")
                return nil
            }


            print("dataToImage: starting new method")
            var srgbArray = [UInt32](repeating: 0xFF204080, count: width * height)
            for row in 0 ..< height
            {
                for col in 0 ..< width
                {
                    let offset = 4 * (row * width + col)
                    let S : UInt32 = 0xff // UInt32(pixelValues[offset + 3])
                    let R : UInt32 = UInt32(pixelValues[offset + 0])
                    let G : UInt32 = UInt32(pixelValues[offset + 1])
                    let B : UInt32 = UInt32(pixelValues[offset + 2])
                    let pixelValue = (S << 24) | (R << 16) | (G << 8) | B
                    let index = row * width + col
                    srgbArray[index] = pixelValue
                }
            }
            print("dataToImage: calling withUnsafeMutableBytes")
            let newImg = srgbArray.withUnsafeMutableBytes { (ptr) -> CGImage in
                print("dataToImage: creating context")
                let ctx = CGContext(
                    data: ptr.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: bitsPerComponent,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue + CGImageAlphaInfo.premultipliedFirst.rawValue)!
                print("dataToImage: making image")
                let img = ctx.makeImage()!
                print("dataToImage: created image")
                return img
            }
            print("dataToImage: returning image")
            return newImg
            
            // CGImageCreate: invalid image bits/component: 8 bits/pixel 24 alpha info = kCGImageAlphaNone

            /*

             
             // faster ways to do this...trying to be clear
             var newData = [UInt8](repeating: 0, count: totalBytes)
             for i in 0 ..< totalBytes
             {
                 newData[i] = pixelValues[i]
             }
             // this comes from https://stackoverflow.com/a/34675717/11615696
            imageRef = withUnsafePointer(to: &newData,
                                         
                // anonymous function passed to withUnsafePointer
                {
                    // signature of the anonymous function (takes the pointer, returns a CGImage?)
                    ptr -> CGImage? in
                    
                    // body of anonymous function
                    var imageRef: CGImage? = nil
                    let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
                    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue).union(CGBitmapInfo()) // not sure about this
                    let data = UnsafeRawPointer(ptr.pointee).assumingMemoryBound(to: UInt8.self)

                    // create a no-op anonymous callback
                    let releaseData: CGDataProviderReleaseDataCallback =
                    {
                        (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in // huh?
                    }
                    
                    if let providerRef = CGDataProvider(dataInfo: nil, data: data, size: totalBytes, releaseData: releaseData) {
                        imageRef = CGImage(width: width,
                                           height: height,
                                           bitsPerComponent: bitsPerComponent,
                                           bitsPerPixel: bitsPerPixel,
                                           bytesPerRow: bytesPerRow,
                                           space: colorSpaceRef,
                                           bitmapInfo: bitmapInfo,
                                           provider: providerRef,
                                           decode: nil,
                                           shouldInterpolate: false,
                                           intent: CGColorRenderingIntent.defaultIntent)
                    }
                    return imageRef
                }
            )
            */
        }
        else
        {
            print("dataToImage: passed null pixelValues?")
        }
        return nil
    }
}

extension UIImage
{
    public func blend(_ img: UIImage) -> UIImage?
    {
        let size = self.size
        UIGraphicsBeginImageContext(size)
        
        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.draw(in: areaSize)
        
        img.draw(in: areaSize, blendMode: .normal, alpha: 0.5)
        
        let blended = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return blended
    }
    // pass CIColor(red: 0.7, green: 0.7, blue: 0.7)
    // see https://www.hackingwithswift.com/example-code/media/how-to-desaturate-an-image-to-make-it-black-and-white
    public func tint(_ ciColor: CIColor, _ intensity: CGFloat = 1.0) -> UIImage?
    {
        guard let currentCGImage = self.cgImage else { return nil }
        let currentCIImage = CIImage(cgImage: currentCGImage)
        
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(currentCIImage, forKey: "inputImage")
        
        // set a gray value for the tint color
        filter?.setValue(ciColor, forKey: "inputColor")
        filter?.setValue(intensity, forKey: "inputIntensity")
        
        print("generating tinted image")
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            print("returning tinted image")
            return UIImage(cgImage: cgimg)
        }
        return nil
    }
    
    public func crop(percent: CGFloat) -> UIImage?
    {
        let size = CGSize(width: self.size.width * percent, height: self.size.height * percent)
        return self.crop(to: size)
    }
    
    // https://stackoverflow.com/a/38777678/11615696
    public func crop(to: CGSize) -> UIImage?
    {
        guard let cgi = self.cgImage else { return nil }
        let origSize: CGSize = self.size
        
        print("Crop: crop image from (\(origSize.width), \(origSize.height) to (\(to.width), \(to.height))")
        
        let posX: CGFloat = (origSize.width/2) - (to.width/2)
        let posY: CGFloat = (origSize.height/2) - (to.height/2)
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: to.width, height: to.height)
        print("Crop: new rect = x: \(posX), y: \(posY), width: \(to.width), height: \(to.height)")
        
        // Create bitmap image from context using the rect
        guard let cgiCropped = cgi.cropping(to: rect) else { return nil }
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let imgCropped = UIImage(cgImage: cgiCropped) // , scale: self.scale, orientation: self.imageOrientation)
        // what if we just returned this?
        
        UIGraphicsBeginImageContextWithOptions(to, false, 1.0) // self.scale)
        imgCropped.draw(in: CGRect(x: 0, y: 0, width: to.width, height: to.height))
        let imgFinal = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let imgFinal = imgFinal
        {
            print("Crop: new image = (\(imgFinal.size.width), \(imgFinal.size.height))")
            return imgFinal
        }
        else
        {
            print("Crop: error")
            return nil
        }
    }
    
    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-CJBDCFBH
    public func diff(_ rhs: UIImage) -> UIImage?
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
    
    public func resize(_ percent: CGFloat) -> UIImage?
    {
        let newHeight = size.height * percent
        let newWidth = size.width * percent
        let newSize = CGSize(width: newWidth, height: newHeight)
        print("resize: resize image by \(percent) from (\(size.width), \(size.height)) to (\(newWidth), \(newHeight))")
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        print("resize: new image: (\(newImage.size.width), \(newImage.size.height))")
        return newImage
    }
    
    // doesn't really matter if input image was already in greyscale or not
    public func normalizeGrayscale() -> UIImage?
    {
        print("norm: getting CGImage")
        if let cgi = self.cgImage
        {
            print("norm: got CGImage size (\(cgi.width), \(cgi.height))")
            print("norm: calling pixelValues")
            
            let width = cgi.width
            let height = cgi.height
            
            if let data = Util.pixelValues(cgi)
            {
                let pixels = width * height
                print("norm: (\(width), \(height)) = \(pixels) pixels (\(data.count) bytes)")

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
                    
                    if gray > hi
                    {
                        hi = gray
                    }
                    
                    if gray < lo
                    {
                        lo = gray
                    }

                    if i % 1000000 == 0 || i + 1 == pixels
                    {
                        print("pixel \(i): lo \(lo), high \(hi), R \(R), G \(G), B \(B), gray \(gray)")
                    }
                }

                print("norm: source intensity range (\(lo), hi \(hi))")
                if hi == lo
                {
                    print("norm: nothing to normalize (lo == hi)")
                    return nil
                }
                
                var newData = [UInt8](repeating: 0, count: pixels * 4)

                for i in 0 ..< pixels
                {
                    let offset = i * 4

                    let R = Float(data[offset+0])
                    let G = Float(data[offset+1])
                    let B = Float(data[offset+2])
                    
                    let gray = (R + G + B) / 3.0
                    let norm = (UInt8)(((gray - lo) / (hi - lo)) * 255.0)
                    newData[offset+0] = norm
                    newData[offset+1] = norm
                    newData[offset+2] = norm
                    
                    if i % 1000000 == 0 || i + 1 == pixels
                    {
                        print("pixel \(i): lo \(lo), high \(hi), R \(R), G \(G), B \(B), gray \(gray), norm \(norm)")
                    }
                }
                
                print("norm: generating CGImage from data")
                if let newCgi = Util.dataToImage(fromPixelValues: newData, width: width, height: height)
                {
                    print("norm: generating UIImage from CGImage")
                    let newImg = UIImage(cgImage: newCgi)
                    // CGImageRelease(newCgi)

                    print("norm: success")
                    return newImg
                }
                else
                {
                    print("norm: failed to generate CGImage from data")
                }
            }
            else
            {
                print("norm: failed to extract data")
            }
        }
        else
        {
            print("norm: can't get self.CGImage")
        }
        
        print("norm: error")
        return nil
    }
   
    public func diffGrayscale(_ rhs: UIImage) -> UIImage?
    {
        let cgiA = self.cgImage!
        let cgiB = rhs.cgImage!
        
        let widthA = cgiA.width
        let heightA = cgiA.height

        let widthB = cgiB.width
        let heightB = cgiB.height
        
        if let dataA = Util.pixelValues(cgiA)
        {
            if let dataB = Util.pixelValues(cgiB)
            {
                let lenA = dataA.count
                let lenB = dataB.count
                
                print("diff2: A: width \(widthA), height \(heightA), length \(lenA)")
                print("diff2: B: width \(widthB), height \(heightB), length \(lenB)")
                
                if lenA != lenB || widthA != widthB || heightA != heightB
                {
                    print("ERROR: diff2 requires same length, width and height")
                    return nil
                }

                var newData = [UInt8](repeating: 0, count: lenA)

                let pixels = widthA * heightA
                for i in 0 ..< pixels
                {
                    let offset = i * 4
                    
                    // assume that R, G and B are identical, so just grab Red
                    let grayA = Float(dataA[offset])
                    let grayB = Float(dataB[offset])
                    
                    let grayDiff = (UInt8)(abs(grayA - grayB))
                    
                    newData[offset+0] = grayDiff
                    newData[offset+1] = grayDiff
                    newData[offset+2] = grayDiff
                }
                
                if let newCgi = Util.dataToImage(fromPixelValues: newData, width: widthA, height: heightA)
                {
                    let img = UIImage(cgImage: newCgi)
                    // CGImageRelease(newCgi)
                    return img
                }
                
                print("normalize: error")
                return nil

            }
        }
                
        return nil
    }
    
    public func mirrorHorizontal() -> UIImage?
    {
        return UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: .leftMirrored)
    }
    
    public func orientationToString() -> String
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
    
    // https://stackoverflow.com/a/47402811/11615696
    public func rotate(radians: Float, horizFlip: Bool = false, vertFlip: Bool = false) -> UIImage?
    {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        let x = CGFloat(vertFlip ? -1.0 : 1.0)
        let y = CGFloat(horizFlip ? -1.0 : 1.0)
        context.scaleBy(x: x, y: y)
        
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
