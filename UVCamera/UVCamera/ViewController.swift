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
        
        // makes Core Graphics segfaults a bit more verbose
        setenv("CGBITMAP_CONTEXT_LOG_ERRORS", "1", 1)
    }

    @IBAction func displayHelp(_ sender: Any)
    {
        if let url = URL(string: "https://mco.wasatchphotonics.com/uv/")
        {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        print("preparing for transition")
        if let vc = segue.destination as? CameraViewController
        {
            print("transitioning to CameraViewController")
            vc.state = state
        }
    }

    @IBAction func saveComponentsCallback(_ sender: Any) {
        state?.saveComponents = switchValue(sender)
    }
    
    func switchValue(_ sender: Any) -> Bool
    {
        let flag = sender as! UISwitch
        return flag.isOn
    }
}
