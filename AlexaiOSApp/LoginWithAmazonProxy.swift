//
//  LoginWithAmazonProxy.swift
//  Alexa iOS App
//
//  Created by Bling on 2/11/17.
//  Copyright © 2017 Bling. All rights reserved.
//

import Foundation
import LoginWithAmazon

class LoginWithAmazonProxy {

    static let sharedInstance = LoginWithAmazonProxy()

    func login(delegate: AIAuthenticationDelegate) {
        AIMobileLib.authorizeUser(forScopes: Settings.Credentials.SCOPES, delegate: delegate, options: [kAIOptionScopeData: Settings.Credentials.SCOPE_DATA])
    }
    
    func logout(delegate: AIAuthenticationDelegate) {
        AIMobileLib.clearAuthorizationState(delegate)
    }
    
    func getAccessToken(delegate: AIAuthenticationDelegate) {
        AIMobileLib.getAccessToken(forScopes: Settings.Credentials.SCOPES, withOverrideParams: nil, delegate: delegate)
    }
    
    func getProfile(delegate: AIAuthenticationDelegate) {
        AIMobileLib.getProfile(delegate)
        
        //AIMobileLib.getProfile(<#T##authenticationDelegate: AIAuthenticationDelegate!##AIAuthenticationDelegate!#>, withOptions: <#T##[AnyHashable : Any]!#>)
    }
}
