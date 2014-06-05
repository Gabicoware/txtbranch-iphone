//
//  QueryableList.m
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "QueryableList.h"
#import "ASIHTTPRequest.h"
#import "NSDictionary+QueryString.h"
#import "NSURL+txtbranch.h"

@interface QueryableList()

@property (nonatomic, strong) ASIHTTPRequest* request;

@end

@implementation QueryableList{
    ASIHTTPRequest* _request;
}
@synthesize query=_query;

-(void)refresh{
    
    [_request cancel];
    
    NSString* path = nil;
    if ([self.query allValues].count > 0 ) {
        NSString* queryString = [self.query queryStringValue];
        path = [NSString stringWithFormat:@"%@?%@",self.basePath, queryString] ;
    }else{
        path = self.basePath ;
    }
    NSURL* URL = [NSURL tbURLWithPath:path];
    
    [self setRequest:[ASIHTTPRequest requestWithURL:URL]];
    [_request setTimeOutSeconds:20];
    
    [_request setDelegate:self];
    [_request setDidFailSelector:@selector(listRequestFailed:)];
    [_request setDidFinishSelector:@selector(listRequestFinished:)];
    
    [_request startAsynchronous];
}

-(void)listRequestFinished:(ASIHTTPRequest*)request{
    
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        self.items = result[@"result"];
    }
}

-(void)listRequestFailed:(ASIHTTPRequest*)sender{
    NSLog(@"");
}








@end
