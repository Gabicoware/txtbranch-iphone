//
//  Inbox.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Inbox.h"

@implementation Inbox

-(void)refresh{
    if (self.list == nil) {
        self.list = [[QueryableList alloc] init];
        self.list.basePath = @"/api/v1/notifications";
        self.list.query = @{};
        [self.list addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:NULL];
    }
    [self.list refresh];

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self updateUnreadCount];
}

#define LastReadNotificationKeyKey @"com.txtbranch.LastReadNotificationKeyKey"

-(void)setLastReadNotificationKey:(NSString *)lastReadNotificationKey{
    if (![self.lastReadNotificationKey isEqualToString:lastReadNotificationKey]) {
        if (lastReadNotificationKey == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:lastReadNotificationKey];
        }else{
            [[NSUserDefaults standardUserDefaults] setObject:lastReadNotificationKey forKey:LastReadNotificationKeyKey];
        }
        [self updateUnreadCount];
    }
}

-(NSString*)lastReadNotificationKey{
    return [[NSUserDefaults standardUserDefaults] stringForKey:LastReadNotificationKeyKey];
}

-(void)updateUnreadCount{
    NSArray* keys = [self.list.items valueForKey:@"key"];
    NSUInteger index = [keys indexOfObject:self.lastReadNotificationKey];
    if ( index == NSNotFound ) {
        self.unreadCount = keys.count;
    }else{
        self.unreadCount = index;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:InboxUnreadCountDidUpdate object:self];
}

@end
