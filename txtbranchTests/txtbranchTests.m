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
#import "Tree.h"

#define TestServer1 @{@"address":@"http://example1.com",@"name":@"someaddress1"}
#define TestServer2 @{@"address":@"http://example2.com",@"name":@"someaddress2"}

@interface IsModeratorTree : Tree

@end

@implementation IsModeratorTree

-(BOOL)isModerator{
    return YES;
}

@end

@interface IsNotModeratorTree : Tree

@end

@implementation IsNotModeratorTree

-(BOOL)isModerator{
    return NO;
}

@end

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

-(void)testIsModeratorTreeLogic{
    Tree* tree = [[IsModeratorTree alloc] initWithName:@"tree"];
    tree.data = @{@"branch_max":@(1),
                  @"link_max":@(64),
                  @"content_max":@(64),
                  @"link_moderator_only":@(0),
                  @"content_moderator_only":@(0)};
    
    tree.branches = @{@"root_branch": @{@"key":@"root_branch"}};
    
    SaveBranchStatus s;
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"aaaaaaa",@"content":@"aaaaaaa"} mutableCopy]];
    
    XCTAssert(s == SaveBranchStatusAllowed, @"should have empty content");
    
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"",@"content":@""} mutableCopy]];
    
    XCTAssert((s & SaveBranchStatusEmptyContent) != 0, @"should have empty content");
    XCTAssert((s & SaveBranchStatusEmptyLink) != 0, @"should have empty link");
    
    tree.data = @{@"branch_max":@(1),
                  @"link_max":@(64),
                  @"content_max":@(64),
                  @"link_moderator_only":@(1),
                  @"content_moderator_only":@(1)};
    
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"aaaaaaa",@"content":@"aaaaaaa"} mutableCopy]];
    
    XCTAssert(s == SaveBranchStatusAllowed, @"should have empty content");
    
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"",@"content":@""} mutableCopy]];
    
    XCTAssert((s & SaveBranchStatusEmptyContent) != 0, @"should have empty content");
    XCTAssert((s & SaveBranchStatusEmptyLink) != 0, @"should have empty link");
    
}

-(void)testNotModeratorTreeLogic{
    Tree* tree = [[IsNotModeratorTree alloc] initWithName:@"tree"];
    tree.data = @{@"branch_max":@(1),
                  @"link_max":@(64),
                  @"content_max":@(64),
                  @"link_moderator_only":@(0),
                  @"content_moderator_only":@(0)};
    
    tree.branches = @{@"root_branch": @{@"key":@"root_branch"}};
    
    SaveBranchStatus s;
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"aaaaaaa",@"content":@"aaaaaaa"} mutableCopy]];
    
    XCTAssert(s == SaveBranchStatusAllowed, @"should have empty content");
    
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"",@"content":@""} mutableCopy]];
    
    XCTAssert((s & SaveBranchStatusEmptyContent) != 0, @"should have empty content");
    XCTAssert((s & SaveBranchStatusEmptyLink) != 0, @"should have empty link");
    
    tree.data = @{@"branch_max":@(1),
                  @"link_max":@(64),
                  @"content_max":@(64),
                  @"link_moderator_only":@(1),
                  @"content_moderator_only":@(1)};
    
    
    
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"",@"content":@""} mutableCopy]];
    
    XCTAssert(s == SaveBranchStatusAllowed, @"should have empty content");
    
    s = [tree saveBranchStatus:[@{@"parent_branch_key":@"root_branch",@"link":@"aaaaaaa",@"content":@"aaaaaaa"} mutableCopy]];
    
    XCTAssert((s & SaveBranchStatusModeratorOnlyContent) != 0, @"should have empty content");
    XCTAssert((s & SaveBranchStatusModeratorOnlyLink) != 0, @"should have empty link");
    
    
    tree.branches = @{@"somebranch":@{@"key":@"somebranch",@"content":@"content",@"link":@"link"},@"root_branch": @{@"key":@"root_branch"}};

    s = [tree saveBranchStatus:[@{@"key":@"somebranch",@"link":@"aaaaaaa",@"content":@"aaaaaaa"} mutableCopy]];
    
    XCTAssert((s & SaveBranchStatusModeratorOnlyContent) != 0, @"should have empty content");
    XCTAssert((s & SaveBranchStatusModeratorOnlyLink) != 0, @"should have empty link");
    
    //allowed to keep links the same
    s = [tree saveBranchStatus:[@{@"key":@"somebranch",@"link":@"link",@"content":@"content"} mutableCopy]];
    
    XCTAssert(s == SaveBranchStatusAllowed, @"should have empty content");
    
    
}

@end
