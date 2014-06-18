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
#import "Messages.h"
#import "AFHTTPSessionManager+txtbranch.h"

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateTreeNotification:) name:@"UpdateTree" object:nil];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleUpdateTreeNotification:(NSNotification*)notification{
    if ([notification.object isEqualToString:self.treeName]) {
        [self loadTree:_treeName];
    }
}

#define IntegerValue(key) ([self.data[key] respondsToSelector:@selector(integerValue)] ? [self.data[key] integerValue] : 0)
#define BoolValue(key) ([self.data[key] respondsToSelector:@selector(boolValue)] ? [self.data[key] boolValue] : 0)

-(NSUInteger)contentMax{
    return IntegerValue(@"content_max");

}

-(BOOL)contentModeratorOnly{
    return BoolValue(@"content_moderator_only");
}

-(NSUInteger)linkMax{
    return IntegerValue(@"link_max");
}

-(BOOL)linkModeratorOnly{
    return IntegerValue(@"link_moderator_only");
}

-(NSUInteger)branchMax{
    return BoolValue(@"branch_max");
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
    
    BOOL hasParent = [branch[@"parent_branch_key"] isKindOfClass:[NSString class]];
    
    [_branches enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary* obj, BOOL *stop) {
        
        hasChildren |= [branchKey isEqual:obj[@"parent_branch_key"]];
        
    }];
    
    return canEdit && hasParent && !hasChildren && branch[@"parent_branch_key"] != nil;
}


-(AddBranchStatus)addBranchStatus:(NSString *)branchKey{
    if (![[AuthenticationManager instance] isLoggedIn]) {
        return AddBranchStatusNeedsLogin;
    }else{
        NSArray* branches = [self childBranches:branchKey];
        if (branches.count < self.branchMax || self.branchMax == 0) {
            return AddBranchStatusAllowed;
        }else{
            return AddBranchStatusHasBranches;
        }
    }
}

#define HasString(string, maxLength) (string != nil && 0 < [(NSString*)string length] && [(NSString*)string length] < maxLength)

-(SaveBranchStatus)saveBranchStatus:(NSMutableDictionary *)branch;{
    SaveBranchStatus result = SaveBranchStatusAllowed;
    
    NSString* link = branch[@"link"];
    NSString* content = branch[@"content"];
    
    NSDictionary* existingBranch = [self branches][branch[@"key"]];
    
    if ([self contentModeratorOnly] && ![self isModerator]) {
        if(0 < content.length && ![existingBranch[@"content"] isEqualToString:content]){
            result |= SaveBranchStatusModeratorOnlyContent;
        }
    }else if (content == nil || content.length == 0) {
        result |= SaveBranchStatusEmptyContent;
    }else if(self.contentMax < content.length ){
        result |= SaveBranchStatusTooLongContent;
    }
    
    if ([self linkModeratorOnly] && ![self isModerator]) {
        if(0 < link.length && ![existingBranch[@"link"] isEqualToString:link]){
            result |= SaveBranchStatusModeratorOnlyLink;
        }
    }else if (link == nil || link.length == 0) {
        result |= SaveBranchStatusEmptyLink;
    }else if(self.linkMax < link.length ){
        result |= SaveBranchStatusTooLongLink;
    }
    
    return result;
}


-(NSArray*)childBranches:(NSString*)parentKey{
    NSString* username = [AuthenticationManager instance].username;
    NSArray* values = [_branches allValues];
    NSIndexSet* indexes = [values indexesOfObjectsPassingTest:^BOOL(NSDictionary* obj, NSUInteger idx, BOOL *stop) {
        return [parentKey isEqualToString:obj[@"parent_branch_key"]] && [obj[@"authorname"] isEqualToString:username];
    }];
    return [values objectsAtIndexes:indexes];
}


-(void)loadTree:(NSString*)name{
    
    [[AFHTTPSessionManager currentManager] GET:@"/api/v1/trees"
                                    parameters:@{@"name":name}
                                       success:^(NSURLSessionDataTask *task, id result) {
                                           if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
                                               self.data = [TreeDefaults dictionaryByMergingValues: result];
                                               //load the root branch immediately if we don't have it
                                               if (_branches[result[@"root_branch_key"]] == nil) {
                                                   [self loadBranches:@[result[@"root_branch_key"]]];
                                               }
                                           }else{
                                               [self showErrors:result[@"result"]];
                                           }
                                           [[NSNotificationCenter defaultCenter] postNotificationName:TreeDidUpdateTreeNotification
                                                                                               object:self
                                                                                             userInfo:nil];
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [self showGeneralError];
                                       }];
}

-(void)loadBranches:(NSArray*)branch_keys{
#warning THIS IS NOT BEING HANDLED BY 
    
    NSMutableArray* params = [@[] mutableCopy];
    for (NSString* branch_key in branch_keys) {
        [params addObject:[NSString stringWithFormat:@"key=%@",branch_key]];
    }
    NSString* path = [NSString stringWithFormat:@"/api/v1/branchs?%@",[params componentsJoinedByString:@"&"]];

    __weak Tree* weakSelf = self;
    [self performGET:path params:nil completion:^(id responseObject) {
        [weakSelf updateBranches:responseObject];
    }];
}

-(void)loadChildBranches:(NSString*)parentBranchKey{
    __weak Tree* weakSelf = self;
    [self performGET:@"/api/v1/branchs" params:@{@"parent_branch_key":parentBranchKey} completion:^(id responseObject) {
        [weakSelf updateBranches:responseObject];
    }];
    
}

-(void)performGET:(NSString*)path params:(NSDictionary*)params completion:(void (^)( id responseObject))success{
    __weak Tree* weakSelf = self;
    [[AFHTTPSessionManager currentManager] GET:path
                                    parameters:params
                                       success:^(NSURLSessionDataTask *task, id result) {
                                           if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
                                               success(result[@"result"]);
                                           }else{
                                               [weakSelf showErrors:result[@"result"]];
                                           }
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [weakSelf showGeneralError];
                                       }];
}

-(void)editBranch:(NSDictionary*)branch{
    
    __weak Tree* weakSelf = self;
    [[AFHTTPSessionManager currentManager] PUT:@"/api/v1/branchs"
                                    parameters:@{@"link":branch[@"link"], @"content":branch[@"content"], @"key":branch[@"key"] }
                                       success:^(NSURLSessionDataTask *task, id result) {
                                           if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
                                               [weakSelf updateBranches:@[result[@"result"]]];
                                           }else{
                                               [weakSelf showErrors:result[@"result"]];
                                           }
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [weakSelf addUnsavedBranch:branch forQuery:@{@"branchKey":branch[@"key"]}];
                                           [weakSelf showEditFormError];
                                       }];
}

-(void)deleteBranch:(NSDictionary*)branch{
    
    NSString* path = [NSString stringWithFormat:@"/api/v1/branchs?key=%@",branch[@"key"]];
    
    ASIHTTPRequest* request = [[ASIHTTPRequest alloc] initWithURL:[NSURL tbURLWithPath:path]];
    
    request.requestMethod = @"DELETE";
    
    request.userInfo = branch;
    
    [self performRequest:request selectorBase:@"deleteBranch"];
    
}

-(void)deleteBranchRequestFailed:(ASIHTTPRequest*)request{
    [self processFailedRequest:request];
}

-(void)deleteBranchRequestFinished:(ASIHTTPRequest*)request{
    [self processRequest:request completion:^(id result) {
        if ( request.userInfo[@"key"] && _branches[request.userInfo[@"key"]] != nil) {
            [_branches removeObjectForKey:request.userInfo[@"key"]];
        }
    }];
}

-(void)addBranch:(NSDictionary*)branch{
    
    ASIFormDataRequest* request = [[ASIFormDataRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/api/v1/branchs"]];
    
    request.userInfo = branch;
    
    for (NSString* key in branch) {
        id value = branch[key];
        [request addPostValue:value forKey:key];
    }
    
    [self performRequest:request selectorBase:@"addBranch"];
    
}

-(void)addBranchRequestFailed:(ASIHTTPRequest*)request{
    [self addUnsavedBranch:request.userInfo forQuery:@{@"parentBranchKey":request.userInfo[@"parent_branch_key"]}];
    [_activeRequests removeObject:request];
    [self showAddFormError];
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
        NSString* message = [[Messages currentMessages] errorMessageForResult:errors];
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    }else{
        [self showGeneralError];
    }
}

-(void)showGeneralError{
    [[[UIAlertView alloc] initWithTitle:nil message:@"There was a problem contacting the server. Sorry!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

-(void)showAddFormError{
    [[[UIAlertView alloc] initWithTitle:@"Could not save" message:@"There was a problem saving the branch to the server. It has been saved if you would like to try adding a branch again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

-(void)showEditFormError{
    [[[UIAlertView alloc] initWithTitle:nil message:@"There was a problem saving the branch to the server. It has been saved if you would like to try editing the branch again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}


@end

@implementation Tree (UnsavedBranches)

#define BRANCHES_KEY @"unsavedbranches"

-(void)addUnsavedBranch:(id)branch forQuery:(id)query{
    NSString* key = [self keyWithQuery:query];
    
    NSMutableDictionary* unsavedBranches = [[[NSUserDefaults standardUserDefaults] objectForKey:BRANCHES_KEY] mutableCopy];
    
    if (key) {
        if (unsavedBranches == nil) {
            unsavedBranches = [NSMutableDictionary dictionary];
        }
        [unsavedBranches setObject:branch forKey:key];
        
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[unsavedBranches copy] forKey:BRANCHES_KEY];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(id)getUnsavedBranchForQuery:(id)query{
    NSString* key = [self keyWithQuery:query];
    
    NSDictionary* unsavedBranches = [[NSUserDefaults standardUserDefaults] objectForKey:BRANCHES_KEY];
    
    id branch = nil;
    
    if ( unsavedBranches && key) {
        branch = unsavedBranches[key];
    }
    
    return branch;
}

-(void)deleteUnsavedBranchForQuery:(id)query{
    NSString* key = [self keyWithQuery:query];
    
    NSMutableDictionary* unsavedBranches = [[[NSUserDefaults standardUserDefaults] objectForKey:BRANCHES_KEY] mutableCopy];
    
    if ( unsavedBranches && key) {
        
        [unsavedBranches removeObjectForKey:key];
        
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[unsavedBranches copy] forKey:BRANCHES_KEY];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(NSString*)keyWithQuery:(id)query{
    NSString* result = nil;
    if (query[@"branchKey"]) {
        result = [NSString stringWithFormat:@"branch-key-%@",query[@"branchKey"]];
    }else if(query[@"parentBranchKey"]){
        result = [NSString stringWithFormat:@"branch-key-%@",query[@"parentBranchKey"]];
    }
    return result;
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

