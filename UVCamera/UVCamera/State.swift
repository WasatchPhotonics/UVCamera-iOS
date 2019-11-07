//
//  State.swift
//  UVCamera
//
//  Created by Mark Zieg on 3/18/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import Foundation
import UIKit

class State
{
    // these images are stored in State, rather than CameraViewController, so
    // they're persisted if the user bounces to the main menu and back
    var imageWide : UIImage? = nil
    var imageNarrow : UIImage? = nil
    var imageProcessed : UIImage? = nil
    
    var saveComponents = false
    
    let processingSettings = ProcessingSettings()
}

class ProcessingSettings
{
    var cameraOffsetPixels : Int = 240

    var generateShadowsInFilteredExposureEnable = true
    var generateShadowsInFilteredExposure : Double = 5.0
    var generateShadowsInFilteredGammaPresetEnable = true
    var generateShadowsInFilteredGammaPreset : String = "E2"
    var generateShadowsInFilteredGammaAdjustEnable = true
    var generateShadowsInFilteredGammaAdjust : Double = 1.5
    var generateShadowsInFilteredContrastEnable = true
    var generateShadowsInFilteredContrast : Double = 2.0
    var generateShadowsInFilteredPosterizeEnable = true
    var generateShadowsInFilteredPosterize : Int = 4

    var generateShadowsInGreenRedExposure : Double = 5.0
    var generateShadowsInGreenRedContrast : Double = 1.5
    
    var generateShadowsInBlueExposure : Double = 5.0
    var generateShadowsInBlueContrast : Double = 1.5
    
    var generateShadowsInUVPreset : String = "L3"

    var finalBlendAlpha : Float = 1.0
}
