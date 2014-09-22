//
//  Inbox.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Inbox.h"
#import "AFHTTPSessionManager+txtbranch.h"

@implementation Inbox

-(instancetype)init{
    if ((self = [super init])) {
        self.basePath = @"/api/v1/notifications";
        self.query = @{};
    }
    return self;
}

-(void)refresh{
    [self refreshWithCompletionHandler:NULL];
}

-(void)refreshWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;
{
    [[AFHTTPSessionManager currentManager] GET:self.basePath parameters:self.query success:^(NSURLSessionDataTask *task, id result) {
        if ([result[@"status"] isEqualToString:@"OK"]) {
            self.items = result[@"result"];
            [self updateUnreadCount];
            if (completionHandler != NULL) {
                completionHandler(UIBackgroundFetchResultNewData);
            }
        }else{
            self.items = nil;
            if (completionHandler != NULL) {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        self.items = nil;
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];

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
    NSArray* keys = [self.items valueForKey:@"key"];
    NSUInteger index = [keys indexOfObject:self.lastReadNotificationKey];
    if ( index == NSNotFound ) {
        self.unreadCount = keys.count;
    }else{
        self.unreadCount = index;
    }
    if ([self shouldSetBadge]) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:self.unreadCount];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:InboxUnreadCountDidUpdate object:self];
}

-(BOOL)shouldSetBadge{
    BOOL result = YES;
    if(NSClassFromString(@"UIUserNotificationSettings")){
        UIUserNotificationSettings* notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        result = (notificationSettings.types & UIUserNotificationTypeBadge) != 0;
    }
    return result;
}

@end
