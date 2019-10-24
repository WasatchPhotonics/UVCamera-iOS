//
//  GammaControl.swift
//  UVCamera
//
//  Created by Mark Zieg on 10/24/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.

import Foundation
import UIKit
import Accelerate

// @see https://developer.apple.com/documentation/accelerate/vimage/adjusting_the_brightness_and_contrast_of_an_image
class GammaHelper
{
    static let presets = [
        "L1": ResponseCurvePreset(label: "L1", boundary: 255, linearCoefficients: [1, 0], gamma: 0),
        "L2": ResponseCurvePreset(label: "L2", boundary: 255, linearCoefficients: [0.5, 0.5], gamma: 0),
        "L3": ResponseCurvePreset(label: "L3", boundary: 255, linearCoefficients: [3, -1], gamma: 0),
        "L4": ResponseCurvePreset(label: "L4", boundary: 255, linearCoefficients: [-1, 1], gamma: 0),
        "E1": ResponseCurvePreset(label: "E1", boundary: 0, linearCoefficients: [1, 0], gamma: 1),
        "E2": ResponseCurvePreset(label: "E2", boundary: 0, linearCoefficients: [1, 0], gamma: 2.2),
        "E3": ResponseCurvePreset(label: "E3", boundary: 0, linearCoefficients: [1, 0], gamma: 1 / 2.2) ]
}

// A structure that wraps piecewise gamma parameters.
struct ResponseCurvePreset
{
    let label: String
    let boundary: Pixel_8
    let linearCoefficients: [Float]
    let gamma: Float
}

extension UIImage
{
    func adjustGamma(preset: String) -> UIImage?
    {
        let name = "adjustGamma"
        
        let responseCurvePreset = GammaHelper.presets[preset]
        if responseCurvePreset == nil
        {
            print("\(name): unknown preset \(preset)")
            return nil
        }
        
        guard let sourceFormat: vImage_CGImageFormat = vImage_CGImageFormat(cgImage: self.cgImage!)
        else
        {
            print("\(name): Unable to create format")
            return nil
        }
        
        // The buffer containing the source image.
        guard var sourceBuffer = try? vImage_Buffer(cgImage: cgImage!, format: sourceFormat)
        else
        {
            print("\(name): failed to create sourceBuffer")
            return nil
        }
        
        // var sourceBuffer: vImage_Buffer =
        // {
        //     guard var sourceImageBuffer = try? vImage_Buffer(cgImage: cgImage!, format: sourceFormat),
        //           var scaledBuffer = try? vImage_Buffer(width: Int(sourceImageBuffer.width), // / 3),
        //                                                 height: Int(sourceImageBuffer.height), // / 3),
        //                                                 bitsPerPixel: sourceFormat.bitsPerPixel)
        //     else
        //     {
        //         fatalError("Unable to create source buffer.")
        //     }
        //
        //     vImageScale_ARGB8888(&sourceImageBuffer, &scaledBuffer, nil, vImage_Flags(kvImageNoFlags))
        //     return scaledBuffer
        // }()
        
        // The 3-channel RGB format of the destination image.
        let rgbFormat: vImage_CGImageFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8 * 3,
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                renderingIntent: .defaultIntent)!
        
        // The buffer containing the image after gamma adjustment
        var destinationBuffer: vImage_Buffer? = nil
        do
        {
            try destinationBuffer = vImage_Buffer(
                width: Int(sourceBuffer.width),
                height: Int(sourceBuffer.height),
                bitsPerPixel: rgbFormat.bitsPerPixel)
        }
        catch
        {
            print("\(name): Unable to create destinastion buffer")
            return nil
        }
        
        if destinationBuffer == nil
        {
            print("\(name): nil destinationBuffer")
            return nil
        }
            
        // Declare the adjustment coefficents based on the currently selected preset
        let boundary: Pixel_8 = responseCurvePreset!.boundary
        
        let linearCoefficients: [Float] = responseCurvePreset!.linearCoefficients
        
        let exponentialCoefficients: [Float] = [1, 0, 0]
        let gamma: Float = responseCurvePreset!.gamma
        
        vImageConvert_RGBA8888toRGB888(&sourceBuffer,
                                       &destinationBuffer!,
                                       vImage_Flags(kvImageNoFlags))
        
        // Create a planar representation of the interleaved destination buffer.
        // Because `destinationBuffer` is 3-channel, assign the planar destinationBuffer a width of 3x the interleaved width.
        var planarDestination = vImage_Buffer(data: destinationBuffer!.data,
                                              height: destinationBuffer!.height,
                                              width: destinationBuffer!.width * 3,
                                              rowBytes: destinationBuffer!.rowBytes)
        
        
        // Perform the adjustment
        vImagePiecewiseGamma_Planar8(&planarDestination,
                                     &planarDestination,
                                     exponentialCoefficients,
                                     gamma,
                                     linearCoefficients,
                                     boundary,
                                     vImage_Flags(kvImageNoFlags))
        
        // Create a 3-channel `CGImage` instance from the interleaved buffer
        let result = try? destinationBuffer!.createCGImage(format: rgbFormat)
        
        if let result = result {
            return UIImage(cgImage: result)
        } else {
            return nil
        }
    }
}
