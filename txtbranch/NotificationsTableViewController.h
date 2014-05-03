//
//  NotificationsTableViewController.h
//  txtbranch
//
//  Created by Daniel Mueller on 4/8/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "txtbranch.h"

@interface NotificationsTableViewController : UITableViewController<Queryable>

@property (nonatomic, copy) NSDictionary* query;

//if nil, no header is displayed
@property (nonatomic, copy) NSString* sectionHeader;

@end
