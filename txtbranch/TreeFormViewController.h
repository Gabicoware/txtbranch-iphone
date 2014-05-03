//
//  TreeFormViewController.h
//  txtbranch
//
//  Created by Daniel Mueller on 4/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "txtbranch.h"

@interface TreeFormViewController : UIViewController<Queryable>

//if the query has a value for the tree_name, will attempt to edit the tree
@property (nonatomic,copy) NSDictionary* query;

@end
