//
//  QueryableList.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "QueryableList.h"
#import "NSDictionary+QueryString.h"
#import "NSURL+txtbranch.h"
#import "AFHTTPSessionManager+txtbranch.h"


@implementation QueryableList
@synthesize query=_query;

-(void)refresh{
    
    [[AFHTTPSessionManager currentManager] GET:self.basePath parameters:self.query success:^(NSURLSessionDataTask *task, id result) {
        if ([result[@"status"] isEqualToString:@"OK"]) {
            self.items = result[@"result"];
        }else{
            self.items = nil;
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        self.items = nil;
    }];
    
}


@end
