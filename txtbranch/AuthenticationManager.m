//
//  AuthenticationManager.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AuthenticationManager.h"
#import "NSURL+txtbranch.h"
#import "KeychainItemWrapper.h"

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
        
        BOOL hasUserName = NO;
        BOOL hasOAuth = NO;
        NSString* username = nil;
        
        for (NSHTTPCookie* cookie in cookies) {
            if ([[cookie name] isEqualToString:@"username"]) {
                hasUserName = YES;
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
        
        if (!hasOAuth && username != nil) {
            _username = username;
            KeychainItemWrapper* item = [[KeychainItemWrapper alloc] initWithService:@"authCookie"
                                                                             account:username
                                                                         accessGroup:AccessGroup];
            NSData* data = [item objectForKey:(__bridge id)kSecValueData];
            
            if (data != nil) {
                NSDictionary* authCookie = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if (authCookie != nil) {
                    NSHTTPCookie* cookie = [NSHTTPCookie cookieWithProperties:authCookie];
                    
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                    hasOAuth = YES;
                }
            }
            
        }
        
        
        _isLoggedIn = hasUserName && hasOAuth;
        
        
    }
    return self;
}

-(void)setIsLoggedIn:(BOOL)isLoggedIn{
    _isLoggedIn = YES;
    
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL tbURL]];
    
    BOOL hasUserName = NO;
    
    NSString* username = nil;
    
    NSDictionary* authCookie = nil;
    
    for (NSHTTPCookie* cookie in cookies) {
        
        if ([[cookie name] isEqualToString:@"username"]) {
            hasUserName = YES;
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
    
    if (authCookie != nil) {
        _username = username;
        KeychainItemWrapper* item = [[KeychainItemWrapper alloc] initWithService:@"authCookie"
                                                                         account:username
                                                                     accessGroup:AccessGroup];
        NSData* data = [NSJSONSerialization dataWithJSONObject:authCookie options:0 error:NULL];
        [item setObject:data forKey:(__bridge id)kSecValueData];
    }
    
}

@end
