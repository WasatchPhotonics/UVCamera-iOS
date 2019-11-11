//
//  SettingsViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 11/7/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit

class SettingsViewController:
        UITableViewController,
        UIPickerViewDelegate,
        UIPickerViewDataSource,
        UITextFieldDelegate
{

    var state : State?

    // TODO: should be enums
    // Note that suffix "Enable" determines if the cell is a Switch or TextField
    let settings = [
        "Camera Offset Px",
        "Sf Exposure Enable",
        "Sf Exposure",
        "Sf Gamma Preset Enable",
        "Sf Gamma Preset Enum",
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
        "Suv Preset Enum",
        "Final Blend Alpha" ]
    
    var activeTextField : UITextField!
    var enumPicker : UIPickerView!
    
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
        let isEnum = name.hasSuffix("Enum")
        let ps = state!.processingSettings

        if isEnum
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCellTextField", for: indexPath) as! SettingsCellTextField
            let tf = cell.myTextField
            let lb = cell.myLabel
            lb?.text = name
            tf?.accessibilityLabel = name
            tf?.delegate = self

                 if name == "Sf Gamma Preset Enum"  { tf?.text = ps.generateShadowsInFilteredGammaPresetEnum }
            else if name == "Suv Preset Enum"       { tf?.text = ps.generateShadowsInUVPresetEnum }

            return cell
        }
        else if isBool
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

                 if name == "Camera Offset Px"      { tf?.text = String(ps.cameraOffsetPixels) }
            else if name == "Sf Exposure"           { tf?.text = String(ps.generateShadowsInFilteredExposure) }
            else if name == "Sf Gamma Adjust"       { tf?.text = String(ps.generateShadowsInFilteredGammaAdjustEnable) }
            else if name == "Sf Contrast"           { tf?.text = String(ps.generateShadowsInFilteredContrast) }
            else if name == "Sf Posterize"          { tf?.text = String(ps.generateShadowsInFilteredPosterize) }
            else if name == "Sgr Exposure"          { tf?.text = String(ps.generateShadowsInGreenRedExposure) }
            else if name == "Sgr Contrast"          { tf?.text = String(ps.generateShadowsInGreenRedContrast) }
            else if name == "Sb Exposure"           { tf?.text = String(ps.generateShadowsInBlueExposure) }
            else if name == "Sb Contrast"           { tf?.text = String(ps.generateShadowsInBlueContrast) }
            else if name == "Final Blend Alpha"     { tf?.text = String(ps.finalBlendAlpha) }
            
            tf?.addDoneToolbar(onDone: (target: self, action: #selector(textFieldDone)))

            return cell
        }
    }
    
    // This is the callback for the "Done" button we added to the numeric/decimal
    // keypads.  There's nothing per-field in it, so it can be shared across all
    // textfields.
    @objc func textFieldDone() -> ()
    {
        self.resignFirstResponder()
        view.endEditing(true)
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

                     if name == "Camera Offset Px"     { ps.cameraOffsetPixels = Int(value) ?? 240 }
                else if name == "Sf Exposure"          { ps.generateShadowsInFilteredExposure = Double(value) ?? 5.0 }
                else if name == "Sf Gamma Preset Enum" { ps.generateShadowsInFilteredGammaPresetEnum = value }
                else if name == "Sf Gamma Adjust"      { ps.generateShadowsInFilteredGammaAdjust = Double(value) ?? 1.5 }
                else if name == "Sf Contrast"          { ps.generateShadowsInFilteredContrast = Double(value) ?? 2.0 }
                else if name == "Sf Posterize"         { ps.generateShadowsInFilteredPosterize = Int(value) ?? 4 }
                else if name == "Sgr Exposure"         { ps.generateShadowsInGreenRedExposure = Double(value) ?? 1.5 }
                else if name == "Sgr Contrast"         { ps.generateShadowsInGreenRedContrast = Double(value) ?? 1.5 }
                else if name == "Sb Exposure"          { ps.generateShadowsInBlueExposure = Double(value) ?? 1.5 }
                else if name == "Sb Contrast"          { ps.generateShadowsInBlueContrast = Double(value) ?? 1.5 }
                else if name == "Suv Preset Enum"      { ps.generateShadowsInUVPresetEnum = value }
                else if name == "Final Blend Alpha"    { ps.finalBlendAlpha = Float(value) ?? 1.0 }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    //--------------------------------------------------------------------------
    // UITextFieldDelegate
    //--------------------------------------------------------------------------

    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        activeTextField = textField
        self.configurePicker(activeTextField)
    }
    
    //--------------------------------------------------------------------------
    // UIPickerViewDelegate, UIPickerViewDataSource
    //--------------------------------------------------------------------------

    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return GammaHelper.supportedPresets.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return GammaHelper.supportedPresets[row]
    }
    
    // func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    // {
    // }

    @objc func pickerDoneClick()
    {
        let row = enumPicker.selectedRow(inComponent: 0)
        
        if row < GammaHelper.supportedPresets.count
        {
            if let tf = activeTextField
            {
                let name = tf.accessibilityLabel
                let value = GammaHelper.supportedPresets[row]
                tf.text = value
                tf.resignFirstResponder()
                print("\(String(describing: name)) changed to \(value)")
            }
        }
    }
    
    @objc func pickerCancelClick()
    {
        activeTextField?.resignFirstResponder()
    }
    
    func configurePicker(_ textField : UITextField)
    {
        // UIPickerView
        enumPicker = UIPickerView(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        enumPicker.delegate = self
        enumPicker.dataSource = self
        // enumPicker.backgroundColor = UIColor.white
        textField.inputView = self.enumPicker
        
        // ToolBar
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton   = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.pickerDoneClick))
        let spaceButton  = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.pickerCancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
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

// see https://stackoverflow.com/a/41048945
extension UITextField {
    func addDoneToolbar(onDone: (target: Any, action: Selector)) {
        let toolbar: UIToolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: onDone.target, action: onDone.action)
        ]
        toolbar.sizeToFit()
        self.inputAccessoryView = toolbar
    }
}
