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

}
