//
//  AFHTTPSessionManager+txtbranch.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/12/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AFHTTPSessionManager+txtbranch.h"
#import "NSURL+txtbranch.h"

@implementation AFHTTPSessionManager (txtbranch)

+(NSMutableDictionary*)managers{
    static NSMutableDictionary* _managers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _managers = [NSMutableDictionary dictionary];
    });
    return _managers;
}

+(instancetype)currentManager{
    NSURL* URL = [NSURL tbURL];
    AFHTTPSessionManager* manager = [self managers][URL];
    if (manager == nil) {
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
        [self managers][URL] = manager;
    }
    return manager;
}

@end
