//
//  TreesViewController.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/5/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "txtbranch.h"

@interface TreesViewController : UITableViewController<Queryable>

-(void)refresh;

@end
