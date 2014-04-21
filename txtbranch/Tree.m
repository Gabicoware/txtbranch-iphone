//
//  Tree.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/17/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Tree.h"
#import "AuthenticationManager.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSURL+txtbranch.h"

NSString* const TreeDidUpdateTreeNotification = @"TreeDidUpdateTreeNotification";
NSString* const TreeDidUpdateBranchesNotification = @"TreeDidUpdateBranchesNotification";
NSString* const TreeDidUpdateBranchesNotificationBranchesUserInfoKey = @"TreeDidUpdateBranchesNotificationBranchesUserInfoKey";


@implementation Tree{
    NSMutableDictionary* _branches;
    NSMutableSet* _activeRequests;
}

-(id)init{
    NSAssert(NO, @"Should not use init directly");
    return nil;
}

-(instancetype)initWithName:(NSString*)treeName{
    if ((self = [super init])) {
        _branches = [NSMutableDictionary dictionary];
        _activeRequests = [NSMutableSet set];
        _treeName = treeName;
        [self loadTree:treeName];
    }
    return self;
}

-(NSUInteger)contentMax{
    return [self.data[@"content_max"] integerValue];

}

-(BOOL)contentModeratorOnly{
    return [self.data[@"content_moderator_only"] boolValue];
}

-(NSUInteger)linkMax{
    return [self.data[@"link_max"] integerValue];
}

-(BOOL)linkModeratorOnly{
    return [self.data[@"link_moderator_only"] boolValue];
}

-(NSUInteger)branchMax{
    return 2;
}

-(NSString*)conventions{
    return self.data[@"conventions"];
}


-(BOOL)canEditBranch:(NSDictionary*)branchKey{

    NSString* username = [AuthenticationManager instance].username;
    
    NSDictionary* branch = _branches[branchKey];

    return [username isEqualToString:branch[@"authorname"]] || [username isEqualToString:self.data[@"moderatorname"]];
}

-(AddBranchStatus)addBranchStatus:(NSString *)branchKey{
    if (![[AuthenticationManager instance] isLoggedIn]) {
        return AddBranchStatusNeedsLogin;
    }else{
        NSArray* branches = [self childBranches:branchKey];
        if (branches.count < self.branchMax) {
            return AddBranchStatusAllowed;
        }else{
            return AddBranchStatusHasBranches;
        }
    }
}

-(NSArray*)childBranches:(NSString*)parentKey{
    NSString* username = [AuthenticationManager instance].username;
    NSArray* values = [_branches allValues];
    NSIndexSet* indexes = [values indexesOfObjectsPassingTest:^BOOL(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
        return [parentKey isEqualToString:obj[@"parent_branch"]] && [obj[@"authorname"] isEqualToString:username];
    }];
    return [values objectsAtIndexes:indexes];
}


-(void)loadTree:(NSString*)name{
    
    NSURL* URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/trees?name=%@",name]];
    
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:URL];
    
    [_activeRequests addObject:request];
    
	[request setTimeOutSeconds:20];
    
	[request setDelegate:self];
	[request setDidFailSelector:@selector(treeRequestFailed:)];
	[request setDidFinishSelector:@selector(treeRequestFinished:)];
	
	[request startAsynchronous];
}

-(void)treeRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
    [_activeRequests removeObject:request];
}

-(void)treeRequestFinished:(ASIHTTPRequest*)request{
    
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        self.data = result[@"result"];
        
        [self loadBranches:@[result[@"result"][@"root_branch_key"]]];
    }
    [_activeRequests removeObject:request];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TreeDidUpdateTreeNotification
                                                        object:self
                                                      userInfo:nil];
}

-(void)loadBranches:(NSArray*)branch_keys{
    NSMutableArray* params = [@[] mutableCopy];
    for (NSString* branch_key in branch_keys) {
        [params addObject:[NSString stringWithFormat:@"branch_key=%@",branch_key]];
    }
    NSURL* URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/branchs?%@",[params componentsJoinedByString:@"&"]]];
    [self loadBranchesURL:URL];
}

-(void)loadChildBranches:(NSString*)parentBranchKey{
    NSURL* URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/branchs?parent_branch_key=%@",parentBranchKey]];
    [self loadBranchesURL:URL];
}

-(void)loadBranchesURL:(NSURL*)URL{
    
    ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:URL];
    
    [_activeRequests addObject:request];
    
	[request setTimeOutSeconds:20];
    
	[request setDelegate:self];
	[request setDidFailSelector:@selector(branchRequestFailed:)];
	[request setDidFinishSelector:@selector(branchRequestFinished:)];
	
	[request startAsynchronous];
    
}

-(void)branchRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
    [_activeRequests removeObject:request];
}

-(void)branchRequestFinished:(ASIHTTPRequest*)request{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    [self updateBranches:result[@"result"]];
    [_activeRequests removeObject:request];
}

-(void)editBranch:(NSDictionary*)branch{
    
    ASIFormDataRequest* request = [[ASIFormDataRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/api/v1/branchs"]];
    
    [_activeRequests addObject:request];
    
    [request addPostValue:branch[@"link"] forKey:@"link"];
    [request addPostValue:branch[@"content"] forKey:@"content"];
    [request addPostValue:branch[@"key"] forKey:@"branch_key"];
    
    
	[request setTimeOutSeconds:20];
    
	[request setDelegate:self];
	[request setDidFailSelector:@selector(editBranchRequestFailed:)];
	[request setDidFinishSelector:@selector(editBranchRequestFinished:)];
	
    request.requestMethod = @"PUT";
    
	[request startAsynchronous];
    
}

-(void)editBranchRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
    [_activeRequests removeObject:request];
}

-(void)editBranchRequestFinished:(ASIHTTPRequest*)request{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if (result != nil && ![result[@"status"] isEqualToString:@"ERROR"]) {
        [self updateBranches:@[result[@"result"]]];
    }
    
    [_activeRequests removeObject:request];
}



-(void)deleteBranch:(NSDictionary*)branch{
    
    NSString* path = [NSString stringWithFormat:@"/api/v1/branchs?branch_key=%@",branch[@"key"]];
    
    ASIHTTPRequest* request = [[ASIHTTPRequest alloc] initWithURL:[NSURL tbURLWithPath:path]];
    
    [_activeRequests addObject:request];
    
	[request setTimeOutSeconds:20];
    
	[request setDelegate:self];
	[request setDidFailSelector:@selector(deleteBranchRequestFailed:)];
	[request setDidFinishSelector:@selector(deleteBranchRequestFinished:)];
	
    request.requestMethod = @"DELETE";
    
	[request startAsynchronous];
    
}

-(void)deleteBranchRequestFailed:(ASIHTTPRequest*)request{
    [_activeRequests removeObject:request];
}

-(void)deleteBranchRequestFinished:(ASIHTTPRequest*)request{
    [_activeRequests removeObject:request];
}

-(void)addBranch:(NSDictionary*)branch{
    
    ASIFormDataRequest* request = [[ASIFormDataRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/api/v1/branchs"]];
    
    [_activeRequests addObject:request];
    
    for (NSString* key in branch) {
        id value = branch[key];
        [request addPostValue:value forKey:key];
    }
    
	[request setTimeOutSeconds:20];
    
	[request setDelegate:self];
	[request setDidFailSelector:@selector(addBranchRequestFailed:)];
	[request setDidFinishSelector:@selector(addBranchRequestFinished:)];
	
	[request startAsynchronous];
    
}

-(void)addBranchRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
    [_activeRequests removeObject:request];
}

-(void)addBranchRequestFinished:(ASIHTTPRequest*)request{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if (result != nil && ![result[@"status"] isEqualToString:@"ERROR"]) {
        [self updateBranches:@[result[@"result"]]];
    }
    [_activeRequests removeObject:request];
}

-(void)updateBranches:(NSArray *)objects{
    
    for (NSDictionary* branch in objects) {
        _branches[branch[@"key"]] = branch;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:TreeDidUpdateBranchesNotification object:self userInfo:@{TreeDidUpdateBranchesNotificationBranchesUserInfoKey:objects}];
}


@end
