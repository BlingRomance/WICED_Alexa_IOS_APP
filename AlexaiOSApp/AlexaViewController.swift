//
//  AlexaViewController.swift
//  Alexa iOS App
//
//  Created by Bling on 2/11/17.
//  Copyright © 2017 Bling. All rights reserved.
//

import UIKit
import LoginWithAmazon
import AVFoundation
import ExpandingMenu

class AlexaViewController: UIViewController, AIAuthenticationDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var pushTalkBtn: UIButton!

    let lwa = LoginWithAmazonProxy.sharedInstance
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder!
    private var audioPlayer: AVAudioPlayer!
    private var isRecording = false
    
    private var avsClient = AlexaVoiceServiceClient()
    private var speakToken: String?
    
    var menuButtonSize: CGSize? = nil
    var menuButton: ExpandingMenuButton? = nil
    var itemLogInOut: ExpandingMenuItem? = nil
    var itemDevicesList: ExpandingMenuItem? = nil
    var itemAddDevice: ExpandingMenuItem? = nil
    
    var db: SQLiteForData?
    var getParameters = ["access_token" : ""]
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Background"))
        configureExpandingMenuButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        avsClient.directiveHandler = self.directiveHandler
        
        if let mydb = appDelegate.db {
            let statement = mydb.select("alexaToken", cond: nil, order: nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                LoginWithAmazon.sharedInstance.loginWithAmazonToken = String(cString: sqlite3_column_text(statement, 1)).replacingOccurrences(of: "\\|", with: "|")
 
                pushTalkBtn.isEnabled = true
                menuButton?.addMenuItems([itemLogInOut!, itemDevicesList!, itemAddDevice!])
                itemLogInOut?.title = "Log Out"
            } else {
                pushTalkBtn.isEnabled = false
                menuButton?.addMenuItems([itemLogInOut!])
                itemLogInOut?.title = "Log In"
            }
            
            sqlite3_finalize(statement)
        }
    }

    override func didReceiveMemoryWarning() {
        // Dispose of any resources that can be recreated.
        super.didReceiveMemoryWarning()
    }

    // Push to Talk button
    @IBAction func onClickPushTalkBtn(_ sender: Any) {
        if (self.isRecording) {
            audioRecorder.stop()
            
            self.isRecording = false
            pushTalkBtn.setTitle("Push to Talk", for: .normal)
            
            do {
                try avsClient.postRecording(audioData: Data(contentsOf: audioRecorder.url))
            } catch let ex {
                print("AVS Client threw an error: \(ex.localizedDescription)")
            }
        } else {
            prepareAudioSession()
            
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            
            self.isRecording = true
            pushTalkBtn.setTitle("Recording, click to stop", for: .normal)
        }
    }
   
    func getUserID(parameters: [String : Any], completion: @escaping (Data) -> Void) {
        var urlComponents = URLComponents(string: "https://api.amazon.com/user/profile")!
        urlComponents.queryItems = []
        
        for (key, value) in parameters{
            guard let value = value as? String else{ return }
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        guard let queryedURL = urlComponents.url else { return }
        let request = URLRequest(url: queryedURL)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print(error as Any)
            } else {
                guard let data = data else { return }
                completion(data)
            }
        }
        
        task.resume()
    }
    
    func prepareAudioSession() {
        do {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = directory.appendingPathComponent(Settings.Audio.TEMP_FILE_NAME)
            try audioRecorder = AVAudioRecorder(url: fileURL, settings: Settings.Audio.RECORDING_SETTING as [String : AnyObject])
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:[AVAudioSessionCategoryOptions.allowBluetooth, AVAudioSessionCategoryOptions.allowBluetoothA2DP])
        } catch let ex {
            print("Audio session has an error: \(ex.localizedDescription)")
        }
    }
    
    func directiveHandler(directives: [DirectiveData]) {
        // Store the token for directive "Speak"
        for directive in directives {
            if (directive.contentType == "application/json") {
                do {
                    let jsonData = try JSONSerialization.jsonObject(with: directive.data) as! [String:Any]
                    let directiveJson = jsonData["directive"] as! [String:Any]
                    let header = directiveJson["header"] as! [String:String]
                    if (header["name"] == "Speak") {
                        let payload = directiveJson["payload"] as! [String:String]
                        self.speakToken = payload["token"]!
                    }
                } catch let ex {
                    print("Directive data has an error: \(ex.localizedDescription)")
                }
            }
        }
        
        // Play the audio
        for directive in directives {
            if (directive.contentType == "application/octet-stream") {
                DispatchQueue.main.async { () -> Void in
                    //self.infoLabel.text = "Alexa is speaking"
                }
                do {
                    self.avsClient.sendEvent(namespace: "SpeechSynthesizer", name: "SpeechStarted", token: self.speakToken!)
                    
                    try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:[AVAudioSessionCategoryOptions.allowBluetooth, AVAudioSessionCategoryOptions.allowBluetoothA2DP])

                    try self.audioPlayer = AVAudioPlayer(data: directive.data)
                    self.audioPlayer.delegate = self
                    self.audioPlayer.prepareToPlay()
                    self.audioPlayer.play()
                } catch let ex {
                    print("Audio player has an error: \(ex.localizedDescription)")
                }
            }
        }
    }
    
    func requestDidSucceed(_ apiResult: APIResult) {
        switch(apiResult.api) {
        case API.authorizeUser:
            print("Authorized")
            lwa.getAccessToken(delegate: self)
            
        case API.getAccessToken:
            print("Login successfully!")
            LoginWithAmazon.sharedInstance.loginWithAmazonToken = apiResult.result as! String?
            getParameters["access_token"] = LoginWithAmazon.sharedInstance.loginWithAmazonToken

            var status: Int = 0
            {
                didSet
                {
                    if status == 1 {
                        status = 0
                        appDelegate.subChannel = "/ampak/\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)"
                        appDelegate.selfSignedSSLSetting()
                        appDelegate.queueSSDP()
                        
                        if let mydb = appDelegate.db {
                            let _ = mydb.insert("alexaToken", rowInfo: ["alexaAccessToken" : "'\(LoginWithAmazon.sharedInstance.loginWithAmazonToken!.replacingOccurrences(of: "|", with: "\\|"))'"])
                            
                            let _ = mydb.insert("alexaUser", rowInfo: ["alexaUserID" : "'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'"])
                            
                            let _ = mydb.createTable("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", columnsInfo: [
                                "devicesID integer primary key autoincrement",
                                "devicesMac text",
                                "devicesName text"])

                            let statement = mydb.select("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", cond: nil, order: nil)
                            if sqlite3_step(statement) == SQLITE_ROW {
                            } else {
                                let alertController = UIAlertController(title: "沒有可以控制的裝置", message: "前往新增裝置", preferredStyle: .alert)
                                
                                let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
                                alertController.addAction(cancelAction)
                                
                                let okAction = UIAlertAction(title: "確定", style: .default, handler: {
                                    (action: UIAlertAction!) -> Void in
                                    self.performSegue(withIdentifier: "DevicesSetup", sender: self)
                                })
                                alertController.addAction(okAction)
                                
                                self.present(alertController, animated: true, completion: nil)
                            }
                            
                            sqlite3_finalize(statement)
                        }
                        
                        pushTalkBtn.isEnabled = true
                        menuButton?.addMenuItems([itemLogInOut!, itemDevicesList!, itemAddDevice!])
                        self.itemLogInOut?.title = "Log Out"
                    }
                    
                    if status == 2 {
                        status = 0
                        self.lwa.logout(delegate: self)
                    }
                }
            }
            
            getUserID(parameters: getParameters, completion: { (data) in
                DispatchQueue.main.async {
                    do {
                        if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                            
                            if jsonResult.value(forKey: "user_id") != nil {
                                LoginWithAmazon.sharedInstance.loginWithAmazonUserID = (jsonResult.value(forKey: "user_id") as! String)
                                status = 1
                            } else {
                                status = 2
                            }
                        }
                    } catch let error as NSError {
                        print(error.localizedDescription)
                    }
                }
            })
            
        case API.clearAuthorizationState:
            print("Logout successfully!")
            if let mydb = appDelegate.db {
                let _ = mydb.delete("alexaToken", cond: nil)
                let _ = mydb.delete("alexaUser", cond: nil)
            }
            
            pushTalkBtn.isEnabled = false
            menuButton?.addMenuItems([itemLogInOut!])
            self.itemLogInOut?.title = "Log In"
            self.isRecording = false
            pushTalkBtn.setTitle("Push to Talk", for: .normal)
            
        default:
            return
        }
    }
    
    func requestDidFail(_ errorResponse: APIError) {
        print("Error: \(errorResponse.error.message)")
    }

    // menu button
    fileprivate func configureExpandingMenuButton() {
        menuButtonSize = CGSize(width: 64.0, height: 64.0)
        menuButton = ExpandingMenuButton(frame: CGRect(origin: CGPoint.zero, size: menuButtonSize!), centerImage: UIImage(named: "chooser-button-tab")!, centerHighlightedImage: UIImage(named: "chooser-button-tab-highlighted")!)
        menuButton?.center = CGPoint(x: self.view.bounds.width - 32.0, y: self.view.bounds.height - 72.0)
        view.addSubview(menuButton!)
        
        itemLogInOut = ExpandingMenuItem(size: menuButtonSize, title: "", image: UIImage(named: "chooser-moment-button")!, highlightedImage: UIImage(named: "chooser-moment-button-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            // Do some action
            if self.itemLogInOut?.title == "Log In" {
                self.lwa.logout(delegate: self)
                self.lwa.login(delegate: self)
            }
            
            if self.itemLogInOut?.title == "Log Out" {
                self.lwa.logout(delegate: self)
            }
        }
        
        itemDevicesList = ExpandingMenuItem(size: menuButtonSize, title: "Devices List", image: UIImage(named: "chooser-moment-button")!, highlightedImage: UIImage(named: "chooser-moment-button-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            // Do some action
            self.performSegue(withIdentifier: "DevicesCell", sender: self)
        }
        
        itemAddDevice = ExpandingMenuItem(size: menuButtonSize, title: "Add Device", image: UIImage(named: "chooser-moment-button")!, highlightedImage: UIImage(named: "chooser-moment-button-highlighted")!, backgroundImage: UIImage(named: "chooser-moment-button"), backgroundHighlightedImage: UIImage(named: "chooser-moment-button-highlighted")) { () -> Void in
            // Do some action
            self.performSegue(withIdentifier: "DevicesSetup", sender: self)
        }
    }
}
