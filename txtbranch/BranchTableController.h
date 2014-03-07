//
//  BranchTableController.h
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    AddBranchStatusAllowed,
    AddBranchStatusNeedsLogin,
    AddBranchStatusHasBranches,
}AddBranchStatus;

@class BranchTableController;

@protocol BranchTableControllerDelegate <NSObject>

-(void)tableController:(BranchTableController*)controller didOpenBranchKey:(NSString*)branchKey;

-(void)tableController:(BranchTableController*)controller addBranch:(NSDictionary*)branch;

-(AddBranchStatus)tableController:(BranchTableController*)controller statusForBranchKey:(NSString*)branchKey;

@end

@interface BranchTableController : NSObject

@property (nonatomic,weak) UITableView* tableView;

@property (nonatomic,strong) NSDictionary* tree;

@property (nonatomic,weak) id<BranchTableControllerDelegate> delegate;

-(instancetype)initWithTableView:(UITableView*)tableView;

-(void)addBranches:(NSArray *)objects;

-(CGRect)addBranchFormRect;

@end
