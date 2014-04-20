//
//  BranchTableController.h
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tree.h"


@interface BranchTableController : NSObject

@property (nonatomic,weak) UITableView* tableView;

@property (nonatomic,strong) Tree* tree;

@property (nonatomic,weak) id delegate;

@property (nonatomic, strong) NSString* currentBranchKey;

-(instancetype)initWithTableView:(UITableView*)tableView;

-(CGRect)addBranchFormRect;

@end
