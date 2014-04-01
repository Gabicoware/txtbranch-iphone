//
//  AuthenticationManager.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthenticationManager : NSObject

@property (nonatomic,assign) BOOL isLoggedIn;

@property (nonatomic,readonly) NSString* username;

+(instancetype)instance;

@end
