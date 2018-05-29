//
//  DemoCell.swift
//  Alexa iOS App
//
//  Created by Bling on 2017/6/29.
//  Copyright © 2017 Bling. All rights reserved.
//

import UIKit
import FoldingCell

class DemoCell: FoldingCell {
    @IBOutlet weak var closeDeviceNumberLabel: UILabel!
    @IBOutlet weak var closeDeviceIDLabel: UILabel!
    @IBOutlet weak var closeDeviceNameLabel: UILabel!
    @IBOutlet weak var openDeviceIDLabel: UILabel!
    @IBOutlet weak var openDeviceNameText: UITextField!
    @IBOutlet weak var redSwitch: UISwitch!
    @IBOutlet weak var blueSwitch: UISwitch!
    @IBOutlet weak var greenSwitch: UISwitch!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var closeNumber: Int = 0 {
        didSet {
            closeDeviceNumberLabel.text = String(closeNumber + 1)
        }
    }
    
    var deviceID: String = "" {
        didSet {
            closeDeviceIDLabel.text = deviceID
            openDeviceIDLabel.text = deviceID
        }
    }
    
    var deviceName: String = "" {
        didSet {
            closeDeviceNameLabel.text = deviceName
            openDeviceNameText.text = deviceName
        }
    }
 
    override func awakeFromNib() {
        foregroundView.layer.cornerRadius = 10
        foregroundView.layer.masksToBounds = true
        super.awakeFromNib()
    }
    
    override func animationDuration(_ itemIndex: NSInteger, type: FoldingCell.AnimationType) -> TimeInterval {
        redSwitch.isOn = redStatus
        blueSwitch.isOn = blueStatus
        greenSwitch.isOn = greenStatus

        let durations = [0.26, 0.2, 0.2]
        return durations[itemIndex]
    }
}

//MARK - Actions
extension DemoCell {
    @IBAction func onClickUpButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":3, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"up\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickDownButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":3, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"down\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickLeftButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":3, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"left\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickRightButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":3, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"right\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickVolUpButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":4, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"up\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickVolDownButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":4, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"down\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickBackButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":3, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"back\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickClickButton(_ sender: Any) {
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":3, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\"click\"}}}", qos: .qos1, retained: false, dup: false)
    }
    
    @IBAction func onClickSaveButton(_ sender: Any) {
        UIApplication.shared.keyWindow?.endEditing(true)
        
        if (openDeviceNameText.text?.lengthOfBytes(using: String.Encoding.utf8))! > 10 {
            appDelegate.showAlertAppDelegate(title: "提示", message: "Device Name最大長度為10", buttonTitle: "確認", window: self.window!)
        } else {
            closeDeviceNameLabel.text = openDeviceNameText.text
            
            if let mydb = appDelegate.db {
                let _ = mydb.update("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", cond: "devicesMac == '\(tableID[closeNumber])'", rowInfo: ["DevicesName":"'\(String(describing: openDeviceNameText.text!))'"])
            }
            
            appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":1, \"name\":\"\(openDeviceNameText.text!)\", \"action\":\" \", \"color\":\" \"}}}", qos: .qos1, retained: false, dup: false)
        }
    }
    
    @IBAction func onClickRedSwitch(_ sender: UISwitch) {
        var ledVaule: String? = nil
        
        if sender.isOn == true {
            ledVaule = "on"
            finalArray[Int(closeDeviceNumberLabel.text!)! - 1][2] = "1"
        } else {
            ledVaule = "off"
            finalArray[Int(closeDeviceNumberLabel.text!)! - 1][2] = "0"
        }
        
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":0, \"name\":\"\(openDeviceIDLabel.text!)\", \"action\":\"\(ledVaule!)\", \"color\":\"red\"}}}", qos: .qos1, retained: false, dup: false)

        blueSwitch.isOn = false
        greenSwitch.isOn = false
        finalArray[Int(closeDeviceNumberLabel.text!)! - 1][3] = "0"
        finalArray[Int(closeDeviceNumberLabel.text!)! - 1][4] = "0"
    }
    
    @IBAction func onClickBlueSwitch(_ sender: UISwitch) {
        var ledVaule: String? = nil
        
        if sender.isOn == true {
            ledVaule = "on"
            finalArray[Int(closeDeviceNumberLabel.text!)! - 1][3] = "1"
        } else {
            ledVaule = "off"
            finalArray[Int(closeDeviceNumberLabel.text!)! - 1][3] = "0"
        }
        
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":0, \"name\":\"\(openDeviceIDLabel.text!)\", \"action\":\"\(ledVaule!)\", \"color\":\"blue\"}}}", qos: .qos1, retained: false, dup: false)
        
        redSwitch.isOn = false
        greenSwitch.isOn = false
        finalArray[Int(closeDeviceNumberLabel.text!)! - 1][2] = "0"
        finalArray[Int(closeDeviceNumberLabel.text!)! - 1][4] = "0"
    }
    
    @IBAction func onClickGreenSwitch(_ sender: UISwitch) {
        var ledVaule: String? = nil
        
        if sender.isOn == true {
            ledVaule = "on"
            finalArray[Int(closeDeviceNumberLabel.text!)! - 1][4] = "1"
        } else {
            ledVaule = "off"
            finalArray[Int(closeDeviceNumberLabel.text!)! - 1][4] = "0"
        }
        
        appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(openDeviceIDLabel.text!)", withString: "{\"state\":{\"desired\":{\"status\":0, \"name\":\"\(openDeviceIDLabel.text!)\", \"action\":\"\(ledVaule!)\", \"color\":\"green\"}}}", qos: .qos1, retained: false, dup: false)

        redSwitch.isOn = false
        blueSwitch.isOn = false
        finalArray[Int(closeDeviceNumberLabel.text!)! - 1][2] = "0"
        finalArray[Int(closeDeviceNumberLabel.text!)! - 1][3] = "0"
    }
}
