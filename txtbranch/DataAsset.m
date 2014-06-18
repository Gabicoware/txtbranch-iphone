//
//  DataAsset.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "DataAsset.h"
#import "NSURL+txtbranch.h"
#import "AFHTTPSessionManager+txtbranch.h"

NSString* DataAssetDidLoad = @"DataAssetDidLoad";

@implementation DataAsset

+(NSURL*)currentURL{
    return [NSURL tbURLWithPath:[[self class] path]];
}

+(NSString*)path{
    return @"";
}

+(NSMutableDictionary*)assets{
    static NSMutableDictionary* _assets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _assets = [NSMutableDictionary dictionary];
    });
    return _assets;
}

+(instancetype)currentAsset{
    NSURL* URL = [[self class] currentURL];
    DataAsset* asset = [self assets][URL];
    if (asset == nil) {
        asset = [[self class] new];
        [self assets][URL] = asset;
    }
    return asset;
}

-(void)reloadData{
    
    __weak DataAsset* weakSelf = self;
    
    [[AFHTTPSessionManager currentManager] GET:[[self class] path] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        weakSelf.data = responseObject;
        [[NSNotificationCenter defaultCenter] postNotificationName:DataAssetDidLoad object:weakSelf];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        weakSelf.data = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:DataAssetDidLoad object:weakSelf];
    }];
    
}

@end