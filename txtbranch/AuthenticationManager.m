//
//  AuthenticationManager.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AuthenticationManager.h"

@implementation AuthenticationManager

+(instancetype)instance{
    static AuthenticationManager* _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [AuthenticationManager new];
    });
    return _instance;
}

@end
