//
//  Tree.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/17/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Tree.h"
#import "AuthenticationManager.h"
#import "NSURL+txtbranch.h"
#import "Messages.h"
#import "AFHTTPSessionManager+txtbranch.h"
#import "NSFoundation+Ext.h"


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
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
                                           if (responseObject != nil && [responseObject[@"status"] isEqualToString:@"OK"]) {
                                               self.data = [TreeDefaults dictionaryByMergingValues: responseObject[@"result"]];
                                               //load the root branch immediately if we don't have it
                                               if (_branches[self.data[@"root_branch_key"]] == nil) {
                                                   [self loadBranches:@[self.data[@"root_branch_key"]]];
                                               }
                                           }else{
                                               [self showErrors:responseObject[@"result"]];
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
                                       success:^(NSURLSessionDataTask *task, NSDictionary* result) {
                                           
                                           result = [result dictionaryByRemovingNulls];
                                           
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
                                           result = [result dictionaryByRemovingNulls];
                                           if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
                                               [weakSelf updateBranches:@[result[@"result"]]];
                                           }else{
                                               [weakSelf addUnsavedBranch:branch forQuery:@{@"branchKey":branch[@"key"]}];
                                               [weakSelf showEditFormError];
                                               [weakSelf showErrors:result[@"result"]];
                                           }
                                       }
                                       failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [weakSelf addUnsavedBranch:branch forQuery:@{@"branchKey":branch[@"key"]}];
                                           [weakSelf showEditFormError];
                                       }];
}

-(void)deleteBranch:(NSDictionary*)branch{
    
    __weak Tree* weakSelf = self;
    [[AFHTTPSessionManager currentManager] DELETE:@"/api/v1/branchs"
                                       parameters:@{@"key":branch[@"key"]}
                                          success:^(NSURLSessionDataTask *task, id result) {
                                              result = [result dictionaryByRemovingNulls];
                                              if ( [result[@"status"] isEqualToString:@"OK"] && _branches[branch[@"key"]] != nil) {
                                                  [_branches removeObjectForKey:branch[@"key"]];
                                              }
                                          } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                              [weakSelf showGeneralError];
                                          }];
}

-(void)addBranch:(NSDictionary*)branch{
    
    __weak Tree* weakSelf = self;
    [[AFHTTPSessionManager currentManager] POST:@"/api/v1/branchs" parameters:branch success:^(NSURLSessionDataTask *task, id result) {
        result = [result dictionaryByRemovingNulls];
        if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
            id branch = result[@"result"];
            [weakSelf postNotificationName:TreeDidAddBranchesNotification branches:@[branch]];
            [weakSelf updateBranches:@[result]];
        }else{
            [weakSelf showErrors:result[@"result"]];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf addUnsavedBranch:branch forQuery:@{@"parentBranchKey":branch[@"parent_branch_key"]}];
        [weakSelf showAddFormError];
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

-(void)showErrors:(NSArray*)errors{
    NSString* message = [[Messages currentMessages] errorMessageForResult:errors];
    if (message.length > 0) {
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

-(NSDictionary*)branchesForKeys:(NSArray*)keys{
    return [[self.branches dictionaryWithValuesForKeys:keys] dictionaryByRemovingNulls];
}

@end

@implementation Tree (UnsavedBranches)

#define BRANCHES_KEY @"unsavedbranches"

-(void)addUnsavedBranch:(NSDictionary*)branch forQuery:(id)query{
    NSString* key = [self keyWithQuery:query];
    
    NSMutableDictionary* unsavedBranches = [[[NSUserDefaults standardUserDefaults] objectForKey:BRANCHES_KEY] mutableCopy];
    
    if (key) {
        if (unsavedBranches == nil) {
            unsavedBranches = [NSMutableDictionary dictionary];
        }
        
        NSSet* keys = [(NSDictionary*)branch keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
            return ![obj isEqual:[NSNull null]];
        }];
        
        NSDictionary* cleanBranch = [branch dictionaryWithValuesForKeys:[keys allObjects]];
        
        [unsavedBranches setObject:cleanBranch forKey:key];
        
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

