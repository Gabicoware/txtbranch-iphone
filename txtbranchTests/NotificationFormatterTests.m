//
//  NotificationFormatterTests.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/9/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NotificationFormatter.h"

@interface NotificationFormatterTests : XCTestCase

@end

@implementation NotificationFormatterTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNotifications
{
    NSURL* URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"notifications" withExtension:@"json"];
    
    NSData* data = [NSData dataWithContentsOfURL:URL];
    
    NSError* error = nil;
    
    NSArray* notifications = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&error];
    
    XCTAssertNil(error, @"");
    XCTAssertNotNil(notifications, @"");
    
    NotificationFormatter* formatter = [NotificationFormatter new];
    
    
    [notifications enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
        NSMutableAttributedString* result = nil;
        XCTAssertNoThrow((result = [formatter stringWithNotification:obj]), @"");
        XCTAssertNotNil(result, @"");
    }];
    
}

@end
