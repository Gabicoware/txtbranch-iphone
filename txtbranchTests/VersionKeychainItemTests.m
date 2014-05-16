//
//  VersionKeychainItemTests.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/16/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VersionKeychainItem.h"

@interface VersionKeychainItemTests : XCTestCase

@end

@implementation VersionKeychainItemTests

- (void)testVersionKeychainItem
{
    
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * version = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    XCTAssertNotNil(version, @"version should not be nil");
    
    VersionKeychainItem* item = [VersionKeychainItem versionKeychainItem];
    
    XCTAssertNotNil(item, @"item should not be nil");
    
    XCTAssertFalse([item hasVersion:version], @"should not have version");
    
    [item addVersion:version];
    
    XCTAssertTrue([item hasVersion:version], @"should have version");
    
    [item removeVersion:version];
    
    XCTAssertFalse([item hasVersion:version], @"should not have version");
}

@end
