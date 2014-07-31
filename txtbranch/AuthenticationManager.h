//
//  AuthenticationManager.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Inbox.h"

@interface AuthenticationManager : NSObject

@property (nonatomic,readonly) BOOL isLoggedIn;

@property (nonatomic,readonly) NSString* username;

+(instancetype)instance;

//will logout, and clear any additional cookies for the server, and reset the inbox
-(void)resetForServer:(NSString*)server;

-(void)updateLoginState;

-(void)clearCurrentSession;

@property (nonatomic, readonly) Inbox* inbox;

@end

@interface AuthenticationManager (Convenience)

//returns a digit or an empty string
+(NSString*)unreadCountString;

@end
