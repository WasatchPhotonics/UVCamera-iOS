//
//  SettingsViewController.swift
//  UVCamera
//
//  Created by Mark Zieg on 11/7/19.
//  Copyright © 2019 Wasatch Photonics. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate,  UITableViewDataSource {

    var state : State?

    let tableview: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = UIColor.white
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorColor = UIColor.white
        return tv
    }()

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
        setupTableView()
    }

    func setupTableView()
    {
        tableview.delegate = self
        tableview.dataSource = self

        tableview.register(SettingCell.self, forCellReuseIdentifier: "cellId")
        
        view.addSubview(tableview)
        
        NSLayoutConstraint.activate([
            tableview.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            tableview.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            tableview.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let name = settings[row]
        let isBool = name.hasSuffix("Enable")

        let cell = tableview.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! SettingCell
        let sw = cell.mySwitch
        let tf = cell.myTextField
        cell.myLabel.text = name
        cell.backgroundColor = UIColor.white

        if isBool
        {
            tf.isHidden = true
            sw.isHidden = false
            sw.accessibilityLabel = name
            sw.addTarget(self, action: #selector(SettingsViewController.switchChanged), for: UIControl.Event.valueChanged)
        }
        else
        {
            sw.isHidden = true
            tf.isHidden = false
            tf.accessibilityLabel = name
            tf.addTarget(self, action: #selector(SettingsViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        }

        let ps = state!.processingSettings

        if name == "Camera Offset Px"           { tf.text = String(ps.cameraOffsetPixels) }
        
        else if name == "Sf Exposure Enable"    { sw.isOn = ps.generateShadowsInFilteredExposureEnable }
        else if name == "Sf Exposure"           { tf.text = String(ps.generateShadowsInFilteredExposure) }
            
        else if name == "Sf Gamma Preset Enable"{ sw.isOn = ps.generateShadowsInFilteredGammaPresetEnable }
        else if name == "Sf Gamma Preset"       { tf.text = ps.generateShadowsInFilteredGammaPreset }
        
        else if name == "Sf Gamma Adjust Enable"{ sw.isOn = ps.generateShadowsInFilteredGammaAdjustEnable }
        else if name == "Sf Gamma Adjust"       { tf.text = String(ps.generateShadowsInFilteredGammaAdjustEnable) }
        
        else if name == "Sf Contrast Enable"    { sw.isOn = ps.generateShadowsInFilteredContrastEnable }
        else if name == "Sf Contrast"           { tf.text = String(ps.generateShadowsInFilteredContrast)}
            
        else if name == "Sf Posterize Enable"   { sw.isOn = ps.generateShadowsInFilteredPosterizeEnable }
        else if name == "Sf Posterize"          { tf.text = String(ps.generateShadowsInFilteredPosterize)}
        
        else if name == "Sgr Exposure"          { tf.text = String(ps.generateShadowsInGreenRedExposure)}
        else if name == "Sgr Contrast"          { tf.text = String(ps.generateShadowsInGreenRedContrast)}
        else if name == "Sb Exposure"           { tf.text = String(ps.generateShadowsInBlueExposure)}
        else if name == "Sb Contrast"           { tf.text = String(ps.generateShadowsInBlueContrast)}
        else if name == "Suv Preset"            { tf.text = ps.generateShadowsInUVPreset}
        else if name == "Final Blend Alpha"     { tf.text = String(ps.finalBlendAlpha)}
        
        return cell
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

}

// @see https://blog.usejournal.com/easy-tableview-setup-tutorial-swift-4-ad48ec4cbd45
class SettingCell: UITableViewCell {
    
    let cellView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let myLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let myTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.boldSystemFont(ofSize: 16)
        tf.textColor = UIColor.white
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    let mySwitch: UISwitch = {
        let sw = UISwitch()
        return sw
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }

    func setupView() {
        addSubview(cellView)
        cellView.addSubview(myLabel)
        cellView.addSubview(myTextField)
        cellView.addSubview(mySwitch)
        self.selectionStyle = .none
        
        NSLayoutConstraint.activate([
            cellView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            cellView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -10),
            cellView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
            cellView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        myLabel.heightAnchor.constraint(equalToConstant: 200).isActive = true
        myLabel.widthAnchor.constraint(equalToConstant: 200).isActive = true
        myLabel.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        myLabel.leftAnchor.constraint(equalTo: cellView.leftAnchor, constant: 20).isActive = true
        
        myTextField.heightAnchor.constraint(equalToConstant: 200).isActive = true
        myTextField.widthAnchor.constraint(equalToConstant: 200).isActive = true
        myTextField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor).isActive = true
        myTextField.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: 20).isActive = true

        mySwitch.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        // mySwitch.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 20).isActive = true
        // mySwitch.heightAnchor.constraint(equalToConstant: 200).isActive = true
        // mySwitch.widthAnchor.constraint(equalToConstant: 200).isActive = true
        mySwitch.rightAnchor.constraint(equalTo: cellView.rightAnchor).isActive = true
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
