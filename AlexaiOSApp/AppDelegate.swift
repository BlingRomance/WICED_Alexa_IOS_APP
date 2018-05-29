//
//  AppDelegate.swift
//  Alexa iOS App
//
//  Created by Bling on 2/11/17.
//  Copyright © 2017 Bling. All rights reserved.
//

import UIKit
import LoginWithAmazon
import CocoaMQTT
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CocoaMQTTDelegate {
    var window: UIWindow?
    var mqtt: CocoaMQTT?
    var subChannel: String? = nil
    var receiveMac: String?
    var db: SQLiteForData?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.isIdleTimerDisabled = true

        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let sqlitePath = urls[urls.count - 1].absoluteString + "sqlite3.db"

        db = SQLiteForData(path: sqlitePath)
        
        if let mydb = db {
            let _ = mydb.createTable("alexaToken", columnsInfo: [
                "alexaDataID integer primary key autoincrement",
                "alexaAccessToken text"])
            let _ = mydb.createTable("alexaUser", columnsInfo: [
                "alexaDataID integer primary key autoincrement",
                "alexaUserID text"])
            
            let statement = mydb.select("alexaUser", cond: nil, order: nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                LoginWithAmazon.sharedInstance.loginWithAmazonUserID = String(cString: sqlite3_column_text(statement, 1))
            }
            sqlite3_finalize(statement)

            if LoginWithAmazon.sharedInstance.loginWithAmazonUserID != nil {
                subChannel = "/ampak/\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)"
                if subChannel != nil {
                    queueSSDP()
                    selfSignedSSLSetting()
                }
            }
        }
 
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

    // Sends the appropriate URL based on login provider
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return AIMobileLib.handleOpen(url, sourceApplication: UIApplicationOpenURLOptionsKey.sourceApplication.rawValue)
    }
    
    // Prompt Ｂox
    func showAlertAppDelegate(title: String, message: String, buttonTitle: String, window: UIWindow) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.default, handler: nil))
        window.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    //MARK - SSDP
    func queueSSDP() {
        let queue = DispatchQueue(label: "com.ampak.queue.ssdp")
        let name = self.subChannel?.cString(using: String.Encoding.utf8)
        queue.async {
            mainSSDP(UnsafeMutablePointer<Int8>(mutating: name!))
        }
    }
    
    // p12 file
    func getClientCertFromP12File(certName: String, certPassword: String) -> CFArray? {
        // get p12 file path
        let resourcePath = Bundle.main.path(forResource: certName, ofType: "p12")
        
        guard let filePath = resourcePath, let p12Data = NSData(contentsOfFile: filePath) else {
            print("Failed to open the certificate file: \(certName).p12")
            return nil
        }
        
        // create key dictionary for reading p12 file
        let key = kSecImportExportPassphrase as String
        let options : NSDictionary = [key: certPassword]
        
        var items : CFArray?
        let securityError = SecPKCS12Import(p12Data, options, &items)
        
        guard securityError == errSecSuccess else {
            if securityError == errSecAuthFailed {
                print("ERROR: SecPKCS12Import returned errSecAuthFailed. Incorrect password?")
            } else {
                print("Failed to open the certificate file: \(certName).p12")
            }
            return nil
        }
        
        guard let theArray = items, CFArrayGetCount(theArray) > 0 else {
            return nil
        }
        
        let dictionary = (theArray as NSArray).object(at: 0)
        guard let identity = (dictionary as AnyObject).value(forKey: kSecImportItemIdentity as String) else {
            return nil
        }
        let certArray = [identity] as CFArray
        
        return certArray
    }
    
    //MARK - CocoaMQTT
    func selfSignedSSLSetting() {
        let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
        mqtt = CocoaMQTT(clientID: clientID, host: "a1dbtct6edkg34.iot.us-east-1.amazonaws.com", port: 8883)
        mqtt?.username = ""
        mqtt?.password = ""
        mqtt?.keepAlive = 60
        mqtt?.delegate = self
        mqtt?.enableSSL = true
        
        let clientCertArray = getClientCertFromP12File(certName: "awsiot-identity", certPassword: "12345678")
        
        var sslSettings: [String: NSObject] = [:]
        sslSettings[kCFStreamSSLCertificates as String] = clientCertArray
        
        mqtt?.sslSettings = sslSettings
        mqtt?.connect()
    }
    
    //MARK - Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue)")
        
        if ack == .accept {
            //mqtt.subscribe(subChannel!, qos: CocoaMQTTQOS.qos1)
            mqtt.subscribe("\(subChannel!)/status", qos: CocoaMQTTQOS.qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(String(describing: message.string!))")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        let receiveStr = message.string
        print("++++++++++++++++ \(receiveStr!)")
        receiveMac = nil
        
        if (receiveStr?.range(of: "wiced") != nil) && (receiveStr?.range(of: "-[EXIT]") != nil) {
            if let mydb = db {
                let _ = mydb.delete("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", cond: "devicesMac == '\(String(describing: receiveStr!).replacingOccurrences(of: "-[EXIT]", with: ""))'")
            }
            self.showAlertAppDelegate(title: "提示", message: receiveStr!, buttonTitle: "確認", window: self.window!)
        } else if (receiveStr?.range(of: "red") != nil) && (receiveStr?.range(of: "blue") != nil) && (receiveStr?.range(of: "green") != nil) {
            let myData = receiveStr?.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            let json: JSON = JSON(data: myData!)
            let whereDevice = tableID.index(of: json["id"].stringValue)
            
            if finalArray.count != 0 && finalArray[whereDevice!][1] == "0" {
                finalArray[whereDevice!][1] = "2"
                finalArray[whereDevice!][2] = json["red"].stringValue
                finalArray[whereDevice!][3] = json["blue"].stringValue
                finalArray[whereDevice!][4] = json["green"].stringValue
                
                print(finalArray)
            }
        } else {
            receiveMac = receiveStr
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        _console("mqttDidDisconnect")
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
        if info == "mqttDidDisconnect" {
            selfSignedSSLSetting()
        }
    }
}

