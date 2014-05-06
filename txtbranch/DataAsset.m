//
//  DataAsset.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "DataAsset.h"
#import "NSURL+txtbranch.h"
#import "ASIHTTPRequest.h"

NSString* DataAssetDidLoad = @"DataAssetDidLoad";

@interface DataAsset()

@property (nonatomic, strong) ASIHTTPRequest* request;

@end

@implementation DataAsset

+(NSURL*)currenURL{
    return [NSURL tbURL];
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
    NSURL* URL = [[self class] currenURL];
    DataAsset* asset = [self assets][URL];
    if (asset == nil) {
        asset = [[self class] new];
        [self assets][URL] = asset;
    }
    return asset;
}

-(void)reloadData{
    self.request = [[ASIHTTPRequest alloc] initWithURL:[[self class] currenURL]];
    __weak DataAsset* weakSelf = self;
    [self.request setCompletionBlock:^{
        NSError* error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:[weakSelf.request responseData]
                                                    options:0
                                                      error:&error];
        if (error == nil) {
            weakSelf.data = result;
        }else{
            weakSelf.data = nil;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:DataAssetDidLoad object:weakSelf];
    }];
    
    [self.request setFailedBlock:^{
        weakSelf.data = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:DataAssetDidLoad object:weakSelf];
    }];
    
    [self.request startAsynchronous];
}

@end