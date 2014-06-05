//
//  InboxTableViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/5/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "InboxTableViewController.h"
#import "QueryableList.h"
#import "AuthenticationManager.h"

@implementation InboxTableViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        id object = [self.list.items firstObject];
        
        if (object[@"key"]) {
            [[[AuthenticationManager instance] inbox] setLastReadNotificationKey:object[@"key"]];
        }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


@end
