//
//  NotificationFormatter.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/9/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "NotificationFormatter.h"
#import "NSDictionary+QueryString.h"
#import "NSDate+TimeAgo.h"

@implementation NotificationFormatter{
    NSDateFormatter* _formatter;
}

-(id)init{
    if((self = [super init])){
        self.URLToNotifications = [NSMutableDictionary dictionary];
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return self;
}

-(NSMutableAttributedString*)stringWithNotification:(NSDictionary*)notification{
    
    NSDictionary* normalAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Medium" size:15]};
    
    NSArray* stringSections = [self stringSectionsWithNotification:notification];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:@"" attributes:normalAttributes];
    for (NSDictionary* stringSection in stringSections) {
        
        NSDictionary* attributes = nil;
        
        if ([stringSection[@"type"] isEqualToString:@"item"]) {
            NSDictionary* params = @{@"itemType": stringSection[@"itemType"],
                                     @"notification": notification[@"key"]};
            NSString* queryString = [params queryStringValue];
            NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"txtbranch://?%@",queryString]];
            self.URLToNotifications[URL] = notification;
            attributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Italic" size:15],
                           NSLinkAttributeName:URL,
                           NSForegroundColorAttributeName:[UIColor darkGrayColor]};
        }else{
            attributes = normalAttributes;
        }
        
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:stringSection[@"string"] attributes:attributes]];
    }
    
    return [string copy];
    
}

#define VALID_NOTIFICATION_TYPES @[@"new_branch",@"edit_branch"]


-(NSArray*)stringSectionsWithNotification:(NSDictionary*)notification{
    
    NSMutableArray* array = [NSMutableArray array];
    
    NSString* username = notification[@"from_username"];
    NSString* treename = notification[@"tree_name"];
    NSString* link = notification[@"branch_link"];
    
    NSString* message = @"";
    
    if ([notification[@"notification_type"] isEqualToString:@"new_branch"]) {
        message = @"added a branch";
    }else if ([notification[@"notification_type"] isEqualToString:@"edit_branch"]) {
        message = @"edited a branch";
    }else if ([notification[@"notification_type"] isEqualToString:@"new_tree"]) {
        message = @"added a tree";
    }else if ([notification[@"notification_type"] isEqualToString:@"edit_tree"]) {
        message = @"edited a tree";
    }else{
        message = [NSString stringWithFormat:@"??%@??",notification[@"notification_type"]];
    }
    
    if ([username isKindOfClass:[NSString class]]) {
        [array addObject:@{@"string":username,@"type":@"item",@"itemType":@"username"}];
        [array addObject:@{@"string":@" ",@"type":@"text"}];
    }
    [array addObject:@{@"string":message,@"type":@"text"}];
    [array addObject:@{@"string":@" ",@"type":@"text"}];
    if ([link isKindOfClass:[NSString class]]) {
        [array addObject:@{@"string":@"\"",@"type":@"text"}];
        [array addObject:@{@"string":link,@"type":@"item",@"itemType":@"link"}];
        [array addObject:@{@"string":@"\" ",@"type":@"text"}];
    }
    if ([link isKindOfClass:[NSString class]] && [treename isKindOfClass:[NSString class]]) {
        [array addObject:@{@"string":@"in ",@"type":@"text"}];
    }
    if ([treename isKindOfClass:[NSString class]]) {
        [array addObject:@{@"string":treename,@"type":@"item",@"itemType":@"tree_name"}];
    }
    
    [array addObject:@{@"string":@" ",@"type":@"text"}];
    NSDate* date = [_formatter dateFromString:notification[@"date"]];
    
    [array addObject:@{@"string":[date timeAgo],@"type":@"text"}];
    
    
    return [array copy];
    
}

@end
