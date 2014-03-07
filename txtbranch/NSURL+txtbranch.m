//
//  NSURL+txtbranch.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "NSURL+txtbranch.h"

#if LOCAL
#define URL_FORMAT @"http://localhost:8080%@"
#else
#define URL_FORMAT @"http://txtbranch.gabicoware.com%@"
#endif

@implementation NSURL (txtbranch)

+(NSURL*)tbURLWithPath:(NSString*)path{
    return [NSURL URLWithString:[NSString stringWithFormat:URL_FORMAT,path]];
}

+(NSURL*)tbURL{
    return [NSURL tbURLWithPath:@""];
}
@end
