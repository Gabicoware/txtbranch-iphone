//
//  NotificationsTableViewController.h
//  txtbranch
//
//  Created by Daniel Mueller on 4/8/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "txtbranch.h"

@class QueryableList;

@interface NotificationsTableViewController : UITableViewController<Queryable>

@property (nonatomic, copy) NSDictionary* query;

@property (nonatomic, strong) QueryableList* list;

//if nil, no header is displayed
@property (nonatomic, copy) NSString* sectionHeader;

@end
