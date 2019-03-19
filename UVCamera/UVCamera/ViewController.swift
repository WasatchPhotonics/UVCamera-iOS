//
//  ViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 3/18/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var state : State?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("main ViewController loaded")
        
        state = State()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        print("preparing for transition")
        if let vc = segue.destination as? CameraViewController
        {
            print("transitioning to CameraViewController")
            vc.state = state
            
            if let button = sender as? UIButton
            {
                print("sender was UIButton")
                if let buttonName = button.titleLabel?.text
                {
                    if buttonName.contains("1.8")
                    {
                        print("clicked ƒ/1.8")
                        vc.cameraNum = 1
                    }
                    else if buttonName.contains("2.4")
                    {
                        print("clicked ƒ/2.4")
                        vc.cameraNum = 2
                    }
                    else
                    {
                        print("unrecognized button label")
                        vc.cameraNum = 0
                    }
                }
                else
                {
                    print("segue button has no label")
                }
            }
            else
            {
                print("sender was NOT UIButton")
            }
        }
        else if let vc = segue.destination as? ProcessedViewController
        {
            print("transitioning to ProcessedViewController")
            vc.state = state
        }
    }
}

