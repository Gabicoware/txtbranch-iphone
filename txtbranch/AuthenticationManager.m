//
//  AuthenticationManager.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AuthenticationManager.h"
#import "NSURL+txtbranch.h"
#import "Inbox.h"

#ifdef TARGET_IPHONE_SIMULATOR
#import "KeychainItemWrapper.h"
#endif


#if DEBUG

#define AccessGroup nil

#else

#define AccessGroup @"com.txtbranch"

#endif

#define BackgroundFetchInterval 60*60*3

@implementation AuthenticationManager{
    NSString* _username;
    Inbox* _inbox;
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
#ifdef TARGET_IPHONE_SIMULATOR
    NSHTTPCookie* oauthCookie = nil;
#endif
    NSHTTPCookie* usernameCookie = nil;
    for (NSHTTPCookie* cookie in cookies) {
        if ([[cookie name] isEqualToString:@"username"]) {
            usernameCookie = cookie;
        }
        else if ([[cookie name] isEqualToString:@"dev_appserver_login"])
        {
#ifdef TARGET_IPHONE_SIMULATOR
            //we only store the dev server login
            oauthCookie = cookie;
#endif
            hasOAuth = YES;
        }
        else if ([[cookie name] isEqualToString:@"_simpleauth_sess"])
        {
            hasOAuth = YES;
        }
    }
    
#ifdef TARGET_IPHONE_SIMULATOR
    
    if (!hasOAuth && [usernameCookie value] != nil) {
        KeychainItemWrapper* item = [[KeychainItemWrapper alloc] initWithService:@"authCookie"
                                                                         account:[usernameCookie value]
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
    
#endif

    _isLoggedIn = hasOAuth && usernameCookie != nil && [usernameCookie value] != nil;
    
    
    if (_isLoggedIn) {
        _username = [usernameCookie value];
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:BackgroundFetchInterval];
        
#ifdef TARGET_IPHONE_SIMULATOR
        if (oauthCookie != nil) {
            KeychainItemWrapper* item = [[KeychainItemWrapper alloc] initWithService:@"authCookie"
                                                                             account:_username
                                                                         accessGroup:AccessGroup];
            NSData* data = [NSJSONSerialization dataWithJSONObject:[oauthCookie properties] options:0 error:NULL];
            [item setObject:data forKey:(__bridge id)kSecValueData];
        }
#endif
        
    }else{
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
        if(usernameCookie != nil){
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:usernameCookie];
        }
    }
    
}

-(NSString*)username{
    if ([self isLoggedIn]) {
        return _username;
    }else{
        return nil;
    }
}


-(void)resetForServer:(NSString*)server{
    NSURL* URL = [NSURL URLWithString:server];
    if (URL) {
        NSArray* cookiesToClear = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:URL] copy];
        for (NSHTTPCookie* cookie in cookiesToClear) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
    _inbox = nil;
}

-(Inbox*)inbox{
    if (self.username != nil) {
        if (_inbox == nil) {
            _inbox = [[Inbox alloc] init];
            [_inbox refresh];
        }
    }
    return _inbox;
}

@end

@implementation AuthenticationManager (Convenience)

+(NSString*)unreadCountString{
    NSUInteger unreadCount = [[[self instance] inbox] unreadCount];
    return unreadCount > 0 ? [NSString stringWithFormat:@"%d",(int)unreadCount] : @"" ;
}

@end

