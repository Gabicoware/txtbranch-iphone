//
//  DataAsset.h
//  txtbranch
//
//  Created by Daniel Mueller on 5/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* DataAssetDidLoad;

@interface DataAsset : NSObject

+(instancetype)currentAsset;

+(NSString*)path;

@property (nonatomic, copy) NSDictionary* data;

-(void)reloadData;

@end
