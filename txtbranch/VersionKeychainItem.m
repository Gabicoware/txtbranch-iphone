//
//  VersionKeychainItem.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/16/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "VersionKeychainItem.h"

@implementation VersionKeychainItem

+(instancetype)versionKeychainItem{
#ifdef TARGET_IPHONE_SIMULATOR
    NSString* vendorID = NSStringFromClass([self class]);
#else
    NSString* vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    
    VersionKeychainItem* wrapper = [[VersionKeychainItem alloc] initWithService:@"Versions" account:vendorID accessGroup:@"com.gabicoware"];
    
    return wrapper;
}

-(BOOL)hasVersion:(NSString*)version{
    
    NSData* data = [self objectForKey:(__bridge id)kSecValueData];
    
    NSArray* object = nil;
    
    if (0 < [data length] ) {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }

    return [object containsObject:version];
}

-(void)addVersion:(NSString*)version{
    
    NSData* data = [self objectForKey:(__bridge id)kSecValueData];
    
    NSArray* object = nil;
    
    if (0 < [data length] ) {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    if (object == nil) {
        object = [NSArray array];
    }
    
    object = [object arrayByAddingObject:version];
    data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [self setObject:data forKey:(__bridge id)kSecValueData];
    
}

-(void)removeVersion:(NSString*)version{
    
    NSData* data = [self objectForKey:(__bridge id)kSecValueData];
    
    NSArray* object = nil;
    
    if (0 < [data length] ) {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    if (object != nil) {
        NSMutableArray* marray = [object mutableCopy];
        
        if ([marray containsObject:version]) {
            [marray removeObject:version];
            data = [NSKeyedArchiver archivedDataWithRootObject:marray];
            [self setObject:data forKey:(__bridge id)kSecValueData];
        }
    }
    
}


@end
