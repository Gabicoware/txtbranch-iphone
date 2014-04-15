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

@implementation AuthenticationManager

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
        
        
        
        NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL tbURL]];
        
        BOOL hasOAuth = NO;
        NSString* username = nil;
        
        for (NSHTTPCookie* cookie in cookies) {
            if ([[cookie name] isEqualToString:@"username"]) {
                username = [cookie value];
            }
#if LOCAL
            else if ([[cookie name] isEqualToString:@"dev_appserver_login"])
            {
                hasOAuth = YES;
            }
#endif
            else if ([[cookie name] isEqualToString:@"_simpleauth_sess"])
            {
                hasOAuth = YES;
            }
        }
        
        _isLoggedIn = hasOAuth && username != nil;
        _username = username;
        
        
    }
    return self;
}

-(void)setIsLoggedIn:(BOOL)isLoggedIn{
    _isLoggedIn = isLoggedIn;
    
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL tbURL]];
    
    NSString* username = nil;
    
    NSDictionary* authCookie = nil;
    
    for (NSHTTPCookie* cookie in cookies) {
        
        if ([[cookie name] isEqualToString:@"username"]) {
            username = [cookie value];
        }
#if LOCAL
        else if ([[cookie name] isEqualToString:@"dev_appserver_login"])
        {
            authCookie = [cookie properties];
        }
#endif
        else if ([[cookie name] isEqualToString:@"_simpleauth_sess"])
        {
            authCookie = [cookie properties];
        }
    }
    
    _username = username;
    
}

@end
