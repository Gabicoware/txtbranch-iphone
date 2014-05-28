//
//  AuthenticationManager.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthenticationManager : NSObject

@property (nonatomic,readonly) BOOL isLoggedIn;

@property (nonatomic,readonly) NSString* username;

@property (nonatomic,readonly) NSNumber* unreadCount;

+(instancetype)instance;

//will logout, and clear any additional cookies for the server
-(void)clearCookiesForServer:(NSString*)server;

-(void)updateLoginState;
@end
