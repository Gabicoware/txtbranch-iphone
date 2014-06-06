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

#define BackgroundFetchInterval 60*60*3

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setMinimumBackgroundFetchInterval:BackgroundFetchInterval];
    
    [[UINavigationBar appearance] setTintColor:[UIColor darkGrayColor]];
    
    [self recordLaunch];
    
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


@end
