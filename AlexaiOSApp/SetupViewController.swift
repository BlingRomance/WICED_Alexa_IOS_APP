//
//  SetupViewController.swift
//  Alexa iOS App
//
//  Created by God on 2017/5/25.
//  Copyright © 2017年 Bling. All rights reserved.
//

import UIKit
import SystemConfiguration.CaptiveNetwork
import ExpandingMenu

class SetupViewController: UIViewController {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var txtSSID: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    var container: UIView = UIView()
    var loadingView: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    let airKiss = AirKiss()
    var countdownTimer: Timer?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SetupViewController.setSSID(noti:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        
        mainView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Background"))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        txtSSID.text = fetchSSIDInfo()
        
        if (txtSSID.text?.isEmpty)! {
            let alertController = UIAlertController(title: "Wi-Fi未開啟或連線", message: "前往設定Wi-Fi", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let okAction = UIAlertAction(title: "確定", style: .default, handler: {
                (action: UIAlertAction!) -> Void in
                let url = URL(string: "App-Prefs:root=WIFI")
                let app = UIApplication.shared
                app.open(url!, options: [:], completionHandler: nil)
            })
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
 
    func setSSID(noti: Notification) {
        txtSSID.text = fetchSSIDInfo()
    }
    
    // Select the SSID which phone was connected
    func fetchSSIDInfo() ->  String {
        var currentSSID = ""
        if let interfaces:CFArray = CNCopySupportedInterfaces() {
            for i in 0 ..< CFArrayGetCount(interfaces){
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if unsafeInterfaceData != nil {
                    let interfaceData = unsafeInterfaceData! as Dictionary!
                    for dictData in interfaceData! {
                        if dictData.key as! String == "SSID" {
                            currentSSID = dictData.value as! String
                        }
                    }
                }
            }
        }
        return currentSSID
    }
    
    @IBAction func insertSSID(_ sender: Any) {
        if txtSSID.text!.isEmpty {
            txtSSID.text = fetchSSIDInfo()
        }
    }
    
    @IBAction func startAirKiss(_ sender: Any) {
        UIApplication.shared.keyWindow?.endEditing(true)
        
        if (txtPassword.text?.isEmpty)! {
            let alertController = UIAlertController(title: "提示", message: "請輸入Wi-Fi password", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .default)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.appDelegate.receiveMac = nil
            airKiss.closeConnect()
            btnStart.isEnabled = false
            isCounting = true
            airKiss.setConnect(txtSSID.text, password: txtPassword.text)
        }
    }
    
    // Try to make device connect on the internet in 60 sec, otherwise timeout.
    var remainingSeconds: Int = 0 {
        willSet {
            btnStart.setTitle("連線中...\(newValue)", for: .normal)
            if newValue <= 0 {
                btnStart.setTitle("Start", for: .normal)
                isCounting = false
                btnStart.isEnabled = true

                let alertController = UIAlertController(title: "裝置連線失敗", message: "請重新嘗試", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "確認", style: .default)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                if self.appDelegate.receiveMac != nil {
                    if let mydb = appDelegate.db {
                        let statement = mydb.select("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", cond: "devicesMac = '\(self.appDelegate.receiveMac!)'", order: nil)
                        if sqlite3_step(statement) == SQLITE_ROW {
                            let _ = mydb.update("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", cond: "devicesMac == '\(self.appDelegate.receiveMac!)'", rowInfo: ["devicesMac" : "'\(self.appDelegate.receiveMac!)'", "devicesName" : "''"])
                        } else {
                            let _ = mydb.insert("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", rowInfo: ["devicesMac" : "'\(self.appDelegate.receiveMac!)'", "devicesName" : "''"])
                        }
                        
                        sqlite3_finalize(statement)
                    }
    
                    let alertController = UIAlertController(title: "提示", message: "裝置連線成功", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "確認", style: .default)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    
                    self.appDelegate.receiveMac = nil
                    btnStart.setTitle("Start", for: .normal)
                    isCounting = false
                    btnStart.isEnabled = true
                }
            }
        }
    }
    
    var isCounting = false {
        willSet {
            if newValue {
                countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(SetupViewController.updateTime(_:)), userInfo: nil, repeats: true)
                remainingSeconds = 60
            } else {
                countdownTimer?.invalidate()
                countdownTimer = nil
            }
        }
    }
    
    func updateTime(_ timer: Timer) {
        remainingSeconds -= 1
    }
}
