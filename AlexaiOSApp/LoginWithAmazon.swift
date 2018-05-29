//
//  LoginWithAmazon.swift
//  Alexa iOS App
//
//  Created by Bling on 2/12/17.
//  Copyright © 2017 Bling. All rights reserved.
//

import Foundation

public class LoginWithAmazon: NSObject {
    
    public static let sharedInstance = LoginWithAmazon()
    
    public var loginWithAmazonToken: String! = nil
    public var loginWithAmazonUserID: String! = nil
}
