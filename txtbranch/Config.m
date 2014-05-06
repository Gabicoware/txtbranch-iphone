//
//  Config.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/5/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Config.h"
#import "NSURL+txtbranch.h"
#import "ASIHTTPRequest.h"

@implementation Config

+(NSURL*)currenURL{
    return [NSURL tbURLWithPath:@"/config.json"];
}

+(instancetype)currentConfig{
    return [self currentAsset];
}

@end
