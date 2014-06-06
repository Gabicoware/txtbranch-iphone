//
//  Inbox.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Inbox.h"
#import "ASIHTTPRequest.h"

@interface Inbox()

@property (nonatomic, strong) void (^completionHandler)(UIBackgroundFetchResult);

@end

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
    self.completionHandler = completionHandler;
    [super refresh];

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
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:self.unreadCount];
    [[NSNotificationCenter defaultCenter] postNotificationName:InboxUnreadCountDidUpdate object:self];
}

-(void)listRequestFinished:(ASIHTTPRequest*)request{
    
    [super listRequestFinished:request];
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        [self updateUnreadCount];
        if (self.completionHandler != NULL) {
            self.completionHandler(UIBackgroundFetchResultNewData);
        }
    }else{
        if (self.completionHandler != NULL) {
            self.completionHandler(UIBackgroundFetchResultNoData);
        }
    }
}

-(void)listRequestFailed:(ASIHTTPRequest*)sender{
    [super listRequestFailed:sender];
    if (self.completionHandler) {
        self.completionHandler(UIBackgroundFetchResultFailed);
    }
}


@end
