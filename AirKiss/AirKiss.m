//
//  AirKiss.m
//  WICED IOT
//
//  Created by God on 2017/5/25.
//  Copyright © 2017年 Bling. All rights reserved.
//

#import "AirKiss.h"
#import <JMAirKiss/JMAirKiss.h>

@implementation AirKiss

-(void) setConnect:(NSString *)ssidStr password:(NSString *)pwdStr {
    JMAirKissConnection *airKissConnection;
    
    if (!airKissConnection) {
        airKissConnection = [[JMAirKissConnection alloc] init];
        
        airKissConnection.connectionSuccess = ^() {
            //printf("success");
        };
        airKissConnection.connectionFailure = ^() {
            //printf("error");
        };
    }
    
    [airKissConnection connectAirKissWithSSID:ssidStr password:pwdStr];
}

-(void) closeConnect {
    JMAirKissConnection *airKissConnection;
    
    [airKissConnection closeConnection];
}
@end
