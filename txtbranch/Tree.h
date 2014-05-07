//
//  Tree.h
//  txtbranch
//
//  Created by Daniel Mueller on 4/17/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const TreeDidUpdateTreeNotification;
extern NSString* const TreeDidAddBranchesNotification;
extern NSString* const TreeDidUpdateBranchesNotification;
extern NSString* const TreeNotificationBranchesUserInfoKey;

typedef enum{
    AddBranchStatusAllowed,
    AddBranchStatusNeedsLogin,
    AddBranchStatusHasBranches,
}AddBranchStatus;

typedef enum{
    SaveBranchStatusAllowed = 0,
    SaveBranchStatusEmptyContent = 1 << 0,
    SaveBranchStatusEmptyLink = 1 << 1,
    SaveBranchStatusModeratorOnlyContent = 1 << 2,
    SaveBranchStatusModeratorOnlyLink = 1 << 3
}SaveBranchStatus;

@interface Tree : NSObject

//designated initializer
-(id)initWithName:(NSString*)treeName;

@property (nonatomic, strong) NSDictionary* data;

@property (nonatomic, strong) NSDictionary* branches;

@property (nonatomic, readonly) NSString* treeName;
@property (nonatomic, readonly) NSString* conventions;
@property (nonatomic, readonly) NSUInteger contentMax;
@property (nonatomic, readonly) NSUInteger linkMax;
@property (nonatomic, readonly) NSUInteger branchMax;
@property (nonatomic, readonly) BOOL linkModeratorOnly;
@property (nonatomic, readonly) BOOL contentModeratorOnly;

-(BOOL)canEditBranch:(NSString *)branchKey;
-(BOOL)canDeleteBranch:(NSString*)branchKey;
-(BOOL)isModerator;

-(AddBranchStatus)addBranchStatus:(NSString *)branchKey;
//will return status and potentially mutate the branch
-(SaveBranchStatus)saveBranchStatus:(NSMutableDictionary *)branch;

-(NSArray*)childBranches:(NSString*)parentKey;

-(void)loadBranches:(NSArray*)branch_keys;
-(void)loadChildBranches:(NSString*)parentBranchKey;
-(void)editBranch:(NSDictionary*)branch;
-(void)deleteBranch:(NSDictionary*)branch;
-(void)addBranch:(NSDictionary*)branch;

@end
