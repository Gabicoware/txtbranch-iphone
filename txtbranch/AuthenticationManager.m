//
//  AuthenticationManager.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AuthenticationManager.h"
#import "NSURL+txtbranch.h"

#if DEBUG

#define AccessGroup nil

#else

#define AccessGroup @"com.txtbranch"

#endif

@implementation AuthenticationManager{
    NSString* _username;
}

+(instancetype)instance{
    static AuthenticationManager* _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [AuthenticationManager new];
    });
    return _instance;
}

-(id)init{
    if((self = [super init])){
        
        [self updateLoginState];
        
    }
    return self;
}

-(void)updateLoginState{
    
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL tbURL]];
    
    BOOL hasOAuth = NO;
    NSHTTPCookie* usernameCookie = nil;
    for (NSHTTPCookie* cookie in cookies) {
        if ([[cookie name] isEqualToString:@"username"]) {
            usernameCookie = cookie;
        }
        else if ([[cookie name] isEqualToString:@"dev_appserver_login"])
        {
            hasOAuth = YES;
        }
        else if ([[cookie name] isEqualToString:@"_simpleauth_sess"])
        {
            hasOAuth = YES;
        }
    }
    
    _isLoggedIn = hasOAuth && usernameCookie != nil && [usernameCookie value] != nil;
    if (_isLoggedIn) {
        _username = [usernameCookie value];
    }else if(usernameCookie != nil){
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:usernameCookie];
    }
    
}

-(NSString*)username{
    if ([self isLoggedIn]) {
        return _username;
    }else{
        return nil;
    }
}

-(NSNumber*)unreadCount{
    return @(0.0);
}

-(void)clearCookiesForServer:(NSString*)server{
    NSURL* URL = [NSURL URLWithString:server];
    if (URL) {
        NSArray* cookiesToClear = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:URL] copy];
        for (NSHTTPCookie* cookie in cookiesToClear) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

@end
