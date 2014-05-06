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
#import "Config.h"

NSString* const TreeDidUpdateTreeNotification = @"TreeDidUpdateTreeNotification";
NSString* const TreeDidAddBranchesNotification = @"TreeDidAddBranchesNotification";
NSString* const TreeDidUpdateBranchesNotification = @"TreeDidUpdateBranchesNotification";
NSString* const TreeNotificationBranchesUserInfoKey = @"TreeNotificationBranchesUserInfoKey";

//it is a critical error to not have a moderatorname or tree_name
#define TreeDefaults @{\
@"conventions":@"",\
@"content_max":@(256),@"content_moderator_only":@(NO),@"content_prompt":@"",\
@"link_max":@(256),@"link_moderator_only":@(NO),@"link_prompt":@"",\
}

@interface NSDictionary(Merge)

-(NSDictionary*)dictionaryByMergingValues:(NSDictionary*)values;

@end

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

-(BOOL)isModerator{
    NSString* username = [AuthenticationManager instance].username;
    return [username isEqualToString:self.data[@"moderatorname"]];
}

-(BOOL)canEditBranch:(NSString*)branchKey{

    NSString* username = [AuthenticationManager instance].username;
    
    NSDictionary* branch = _branches[branchKey];

    return [username isEqualToString:branch[@"authorname"]] || [self isModerator];
}

-(BOOL)canDeleteBranch:(NSString*)branchKey{
    
    BOOL canEdit = [self canEditBranch:branchKey];
    
    NSDictionary* branch = _branches[branchKey];
    
    __block BOOL hasChildren = NO;
    
    [_branches enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary* obj, BOOL *stop) {
        
        hasChildren |= [obj[@"parent_branch_key"] isEqualToString:branchKey];
        
    }];
    
    return canEdit && !hasChildren && branch[@"parent_branch_key"] != nil;
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
    
    [self performRequest:request selectorBase:@"tree"];
}

-(void)treeRequestFailed:(ASIHTTPRequest*)request{
    [self processFailedRequest:request];
}

-(void)treeRequestFinished:(ASIHTTPRequest*)request{
        
    [self processRequest:request completion:^(id result) {
        self.data = [TreeDefaults dictionaryByMergingValues: result];
        
        [self loadBranches:@[result[@"root_branch_key"]]];
    }];

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
    
    [self performRequest:request selectorBase:@"branch"];
}

-(void)branchRequestFailed:(ASIHTTPRequest*)request{
    [self processFailedRequest:request];
}

-(void)branchRequestFinished:(ASIHTTPRequest*)request{
    [self processRequest:request completion:^(id result) {
        [self updateBranches:result];
    }];
}

-(void)editBranch:(NSDictionary*)branch{
    
    ASIFormDataRequest* request = [[ASIFormDataRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/api/v1/branchs"]];
    
    [request addPostValue:branch[@"link"] forKey:@"link"];
    [request addPostValue:branch[@"content"] forKey:@"content"];
    [request addPostValue:branch[@"key"] forKey:@"branch_key"];
    
    request.requestMethod = @"PUT";
    
    [self performRequest:request selectorBase:@"editBranch"];
}

-(void)editBranchRequestFailed:(ASIHTTPRequest*)request{
    [self processFailedRequest:request];
}

-(void)editBranchRequestFinished:(ASIHTTPRequest*)request{
    [self processRequest:request completion:^(id result) {
        [self updateBranches:@[result]];
    }];
}

-(void)deleteBranch:(NSDictionary*)branch{
    
    NSString* path = [NSString stringWithFormat:@"/api/v1/branchs?branch_key=%@",branch[@"key"]];
    
    ASIHTTPRequest* request = [[ASIHTTPRequest alloc] initWithURL:[NSURL tbURLWithPath:path]];
    
    request.requestMethod = @"DELETE";
    
    [self performRequest:request selectorBase:@"deleteBranch"];
    
}

-(void)deleteBranchRequestFailed:(ASIHTTPRequest*)request{
    [self processFailedRequest:request];
}

-(void)deleteBranchRequestFinished:(ASIHTTPRequest*)request{
    [self processRequest:request completion:^(id result) {}];
}

-(void)addBranch:(NSDictionary*)branch{
    
    ASIFormDataRequest* request = [[ASIFormDataRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/api/v1/branchs"]];
    
    for (NSString* key in branch) {
        id value = branch[key];
        [request addPostValue:value forKey:key];
    }
    
    [self performRequest:request selectorBase:@"addBranch"];
    
}

-(void)addBranchRequestFailed:(ASIHTTPRequest*)request{
    [self processFailedRequest:request];
}

-(void)addBranchRequestFinished:(ASIHTTPRequest*)request{
    [self processRequest:request completion:^(id result) {
        [self postNotificationName:TreeDidAddBranchesNotification branches:@[result]];
        [self updateBranches:@[result]];
    }];
}

-(void)updateBranches:(NSArray *)objects{
    
    for (NSDictionary* branch in objects) {
        _branches[branch[@"key"]] = branch;
    }
    [self postNotificationName:TreeDidUpdateBranchesNotification branches:objects];
}

-(void)postNotificationName:(NSString*)name branches:(NSArray*)branches{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:@{TreeNotificationBranchesUserInfoKey:branches}];
}

-(void)performRequest:(ASIHTTPRequest*)request selectorBase:(NSString*)selectorBase{
    
    [_activeRequests addObject:request];
    
	[request setTimeOutSeconds:20];
    
	[request setDelegate:self];
    
    SEL failedSelector = NSSelectorFromString([selectorBase stringByAppendingString:@"RequestFailed:"]);
    
    if ([self respondsToSelector:failedSelector]) {
        [request setDidFailSelector:failedSelector];
    }
    
    SEL finishedSelector = NSSelectorFromString([selectorBase stringByAppendingString:@"RequestFinished:"]);
    
    if ([self respondsToSelector:finishedSelector]) {
        [request setDidFinishSelector:finishedSelector];
    }
    
	[request startAsynchronous];
}


-(void)processFailedRequest:(ASIHTTPRequest*)request
{
    NSLog(@"%@",request.responseString);
    [_activeRequests removeObject:request];
    [self showGeneralError];
}
-(void)processRequest:(ASIHTTPRequest*)request completion:(void(^)(id result))completion{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
        
        completion(result[@"result"]);
        
    }else{
        [self showErrors:result[@"result"]];
    }
    [_activeRequests removeObject:request];
}

-(void)showErrors:(NSArray*)errors{
    if (errors.count > 0) {
        NSString* message = [[Config currentConfig] errorMessageForResult:errors];
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    }else{
        [self showGeneralError];
    }
}

-(void)showGeneralError{
    [[[UIAlertView alloc] initWithTitle:nil message:@"There was a problem contacting the server. Sorry!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

@end

@implementation NSDictionary(Merge)

-(NSDictionary*)dictionaryByMergingValues:(NSDictionary*)values{
    NSMutableDictionary* result = [self mutableCopy];
    for (id key in values) {
        if (values[key] != nil && ![values[key] isEqual:[NSNull null]]) {
            result[key] = values[key];
        }
    }
    return [result copy];
}

@end

