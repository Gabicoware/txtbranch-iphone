//
//  Inbox.h
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QueryableList.h"

#define InboxUnreadCountDidUpdate @"com.txtbranch.InboxUnreadCountDidUpdate"

@interface Inbox : QueryableList

//this is readwrite for the sake of KVO, but you probably wouldn't want to
//assign anything to it (other than 0)
@property (nonatomic, assign) NSUInteger unreadCount;

//This is a temporary implementation
@property (nonatomic, assign) NSString* lastReadNotificationKey;

-(void)refreshWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

@end
