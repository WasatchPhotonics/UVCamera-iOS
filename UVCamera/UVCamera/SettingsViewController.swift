//
//  SettingsViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 11/7/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    var state : State?

    // TODO: should be enums
    let settings = [
        "Camera Offset Px",
        "Sf Exposure Enable",
        "Sf Exposure",
        "Sf Gamma Preset Enable",
        "Sf Gamma Preset",
        "Sf Gamma Adjust Enable",
        "Sf Gamma Adjust",
        "Sf Contrast Enable",
        "Sf Contrast",
        "Sf Posterize Enable",
        "Sf Posterize",
        "Sgr Exposure",
        "Sgr Contrast",
        "Sb Exposure",
        "Sb Contrast",
        "Suv Preset",
        "Final Blend Alpha" ]

    override func viewDidLoad()
    {
        print("Settings loading")
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let name = settings[row]
        let isBool = name.hasSuffix("Enable")
        let ps = state!.processingSettings

        if isBool
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCellSwitch", for: indexPath) as! SettingsCellSwitch
            let lb = cell.myLabel
            let sw = cell.mySwitch
            lb?.text = name
            sw?.accessibilityLabel = name
            sw?.addTarget(self, action: #selector(SettingsViewController.switchChanged), for: UIControl.Event.valueChanged)

            if name == "Sf Exposure Enable"    { sw?.isOn = ps.generateShadowsInFilteredExposureEnable }
            else if name == "Sf Gamma Preset Enable"{ sw?.isOn = ps.generateShadowsInFilteredGammaPresetEnable }
            else if name == "Sf Gamma Adjust Enable"{ sw?.isOn = ps.generateShadowsInFilteredGammaAdjustEnable }
            else if name == "Sf Contrast Enable"    { sw?.isOn = ps.generateShadowsInFilteredContrastEnable }
            else if name == "Sf Posterize Enable"   { sw?.isOn = ps.generateShadowsInFilteredPosterizeEnable }
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCellTextField", for: indexPath) as! SettingsCellTextField
            let tf = cell.myTextField
            let lb = cell.myLabel
            lb?.text = name
            tf?.accessibilityLabel = name
            tf?.addTarget(self, action: #selector(SettingsViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)

            if name == "Camera Offset Px"           { tf?.text = String(ps.cameraOffsetPixels) }
            else if name == "Sf Exposure"           { tf?.text = String(ps.generateShadowsInFilteredExposure) }
            else if name == "Sf Gamma Preset"       { tf?.text = ps.generateShadowsInFilteredGammaPreset }
            else if name == "Sf Gamma Adjust"       { tf?.text = String(ps.generateShadowsInFilteredGammaAdjustEnable) }
            else if name == "Sf Contrast"           { tf?.text = String(ps.generateShadowsInFilteredContrast)}
            else if name == "Sf Posterize"          { tf?.text = String(ps.generateShadowsInFilteredPosterize)}
            else if name == "Sgr Exposure"          { tf?.text = String(ps.generateShadowsInGreenRedExposure)}
            else if name == "Sgr Contrast"          { tf?.text = String(ps.generateShadowsInGreenRedContrast)}
            else if name == "Sb Exposure"           { tf?.text = String(ps.generateShadowsInBlueExposure)}
            else if name == "Sb Contrast"           { tf?.text = String(ps.generateShadowsInBlueContrast)}
            else if name == "Suv Preset"            { tf?.text = ps.generateShadowsInUVPreset}
            else if name == "Final Blend Alpha"     { tf?.text = String(ps.finalBlendAlpha)}
            return cell
        }
    }

    @objc func switchChanged(_ sw: UISwitch)
    {
        if let name = sw.accessibilityLabel
        {
            let value = sw.isOn
            print("User changed \(String(describing: name)) to \(String(describing: value))")
            
            let ps = state!.processingSettings

                 if name == "Sf Exposure Enable"       { ps.generateShadowsInFilteredExposureEnable    = value }
            else if name == "Sf Gamma Preset Enable"   { ps.generateShadowsInFilteredGammaPresetEnable = value }
            else if name == "Sf Gamma Adjust Enable"   { ps.generateShadowsInFilteredGammaAdjustEnable = value }
            else if name == "Sf Contrast Enable"       { ps.generateShadowsInFilteredContrastEnable    = value }
            else if name == "Sf Posterize Enable"      { ps.generateShadowsInFilteredPosterizeEnable   = value }
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField)
    {
        if let value = textField.text
        {
            if let name = textField.accessibilityLabel
            {
                print("User changed \(String(describing: name)) to \(String(describing: value))")
                
                let ps = state!.processingSettings

                     if name == "Camera Offset Px"  { ps.cameraOffsetPixels = Int(value) ?? 240 }
                else if name == "Sf Exposure"       { ps.generateShadowsInFilteredExposure = Double(value) ?? 5.0 }
                else if name == "Sf Gamma Preset"   { ps.generateShadowsInFilteredGammaPreset = value }
                else if name == "Sf Gamma Adjust"   { ps.generateShadowsInFilteredGammaAdjust = Double(value) ?? 1.5 }
                else if name == "Sf Contrast"       { ps.generateShadowsInFilteredContrast = Double(value) ?? 2.0 }
                else if name == "Sf Posterize"      { ps.generateShadowsInFilteredPosterize = Int(value) ?? 4 }
                else if name == "Sgr Exposure"      { ps.generateShadowsInGreenRedExposure = Double(value) ?? 1.5 }
                else if name == "Sgr Contrast"      { ps.generateShadowsInGreenRedContrast = Double(value) ?? 1.5 }
                else if name == "Sb Exposure"       { ps.generateShadowsInBlueExposure = Double(value) ?? 1.5 }
                else if name == "Sb Contrast"       { ps.generateShadowsInBlueContrast = Double(value) ?? 1.5 }
                else if name == "Suv Preset"        { ps.generateShadowsInUVPreset = value }
                else if name == "Final Blend Alpha" { ps.finalBlendAlpha = Float(value) ?? 1.0 }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

}

class SettingsCellTextField: UITableViewCell
{
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myTextField: UITextField!
}

class SettingsCellSwitch: UITableViewCell
{
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var mySwitch: UISwitch!
}
