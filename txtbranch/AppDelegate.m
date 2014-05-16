//
//  AppDelegate.m
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AppDelegate.h"
#import "VersionKeychainItem.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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

@end
