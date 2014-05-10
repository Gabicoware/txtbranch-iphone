//
//  NotificationFormatter.h
//  txtbranch
//
//  Created by Daniel Mueller on 5/9/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationFormatter : NSObject

@property (nonatomic, strong) NSMutableDictionary* URLToNotifications;

/* returns an array of string sections
 *
 * each section is an NSDictionary with the following keys
 * string : the string to display
 * type : the type of section; text or item
 * itemType : the itemType of the item; link, tree_name, or username
 *
 */
-(NSArray*)stringSectionsWithNotification:(NSDictionary*)notification;

-(NSMutableAttributedString*)stringWithNotification:(NSDictionary*)notification;

@end
