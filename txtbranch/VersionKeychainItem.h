//
//  VersionKeychainItem.h
//  txtbranch
//
//  Created by Daniel Mueller on 5/16/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "KeychainItemWrapper.h"

@interface VersionKeychainItem : KeychainItemWrapper

//factory method
+(instancetype)versionKeychainItem;

-(BOOL)hasVersion:(NSString*)version;

-(void)addVersion:(NSString*)version;

-(void)removeVersion:(NSString*)version;

@end
