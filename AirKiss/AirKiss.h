//
//  AirKiss.h
//  WICED IOT
//
//  Created by God on 2017/5/25.
//  Copyright © 2017年 Bling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AirKiss : NSObject
-(void) setConnect: (NSString *)ssidStr password: (NSString *)pwdStr;
-(void) closeConnect;
@end
