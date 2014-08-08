//
//  AppDelegate.m
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AppDelegate.h"
#import "VersionKeychainItem.h"
#import "AuthenticationManager.h"
#import "AFHTTPSessionManager+txtbranch.h"
#import "Messages.h"
#import "UIAlertView+Block.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [[UINavigationBar appearance] setTintColor:[UIColor darkGrayColor]];
    
    [self recordLaunch];
    
    [self refreshCookies];
    
    return YES;
}

-(void)recordLaunch{
    //the recorded versions persist between installations.
    //a version can be present in the keyvhain, but the app has been uninstalled and reinstalled
    
    NSString* bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    
    VersionKeychainItem* item = [VersionKeychainItem versionKeychainItem];
    
    if (![item hasVersion:bundleVersion]) {
        [item addVersion:bundleVersion];
    }
    
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler{
    Inbox* inbox = [[AuthenticationManager instance] inbox];
    if (inbox) {
        [inbox refreshWithCompletionHandler:completionHandler];
    }else{
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

//reset cookies when things are borked

-(void)refreshCookies{
    if ([[AuthenticationManager instance] isLoggedIn]) {
        [[AFHTTPSessionManager currentManager] GET:@"/api/v1/userinfos"
                                        parameters:@{@"set_cookie":@"1"}
                                           success:^(NSURLSessionDataTask *task, id responseObject) {
                                               
                                               [[AuthenticationManager instance] updateLoginState];
                                               
                                               BOOL hasStatusError = [responseObject[@"status"] isEqualToString:@"Error"];
                                               BOOL isNotLoggedIn = ![[AuthenticationManager instance] isLoggedIn];
                                               
                                               if(hasStatusError || isNotLoggedIn){
                                                   [[[UIAlertView alloc] initWithTitle:[[Messages currentMessages] resetLoginTitle]
                                                                               message:[[Messages currentMessages] resetLoginMessage]
                                                                              delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                               }
                                               
                                           } failure:^(NSURLSessionDataTask *task, NSError *error) {}];
    }
}


@end
