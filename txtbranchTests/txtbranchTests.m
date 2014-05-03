//
//  txtbranchTests.m
//  txtbranchTests
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURL+txtbranch.h"
#import "ServerList.h"

#define TestServer1 @{@"address":@"http://example1.com",@"name":@"someaddress1"}
#define TestServer2 @{@"address":@"http://example2.com",@"name":@"someaddress2"}

@interface txtbranchTests : XCTestCase

@property (nonatomic,copy) NSArray* existingServers;

@end

@implementation txtbranchTests

- (void)setUp
{
    [super setUp];
    
    self.existingServers = [ServerList instance].servers;
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    NSArray* testServers = [ServerList instance].servers;
    
    for (NSDictionary* testServer in testServers) {
        [[ServerList instance] removeServer:testServer];
    }
    
    for (NSDictionary* server in self.existingServers) {
        [[ServerList instance] addServer:server];
    }
}

- (void)testURLManagement
{
    
    ServerList* serverList = [[ServerList alloc] init];
    
    [serverList addServer:TestServer1];
    [serverList addServer:TestServer2];
    
    ServerList* serverList2 = [[ServerList alloc] init];
    
//    XCTAssertEqualObjects([NSURL basePath], serverList2.servers[0], @"the basepath should be equal to the 0th item in the server list");
    BOOL contains;
    contains = [serverList2.servers containsObject:TestServer1];
    XCTAssertTrue(contains, @"");
    contains = [serverList2.servers containsObject:TestServer2];
    XCTAssertTrue(contains, @"");
    
    [serverList2 removeServer:TestServer1];
    
    ServerList* serverList3 = [[ServerList alloc] init];
    
    contains = [serverList3.servers containsObject:TestServer1];
    XCTAssertFalse(contains, @"");
    
    
    
}

@end
