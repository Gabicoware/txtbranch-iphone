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

NSString* ConfigDidLoad = @"ConfigDidLoad";

@interface Config()

@property (nonatomic, strong) ASIHTTPRequest* request;

@end

@implementation Config

+(NSMutableDictionary*)configs{
    static NSMutableDictionary* _configs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _configs = [NSMutableDictionary dictionary];
    });
    return _configs;
}

+(instancetype)currentConfig{
    Config* config = [self configs][[NSURL tbURL]];
    if (config == nil) {
        config = [Config new];
        [self configs][[NSURL tbURL]] = config;
    }
    return config;
}

-(void)reloadData{
    self.request = [[ASIHTTPRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/config.json"]];
    __weak Config* weakSelf = self;
    [self.request setCompletionBlock:^{
        NSError* error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:[weakSelf.request responseData]
                                                    options:0
                                                      error:&error];
        if (error == nil) {
            weakSelf.data = result;
        }else{
            [weakSelf showError];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ConfigDidLoad object:weakSelf];
    }];
    
    [self.request setFailedBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ConfigDidLoad object:weakSelf];
        [weakSelf showError];
    }];
    
    [self.request startAsynchronous];
}

-(void)showError{
    [[[UIAlertView alloc] initWithTitle:@"Can't connect to server" message:@"There was an error reaching the server. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

-(NSString*)errorMessageForResult:(NSArray*)errors{
    NSMutableArray* messages = [NSMutableArray array];
    
    NSDictionary* errorMessages = self.data[@"error_messages"];
    [errors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (errorMessages[obj]) {
            [messages addObject:errorMessages[obj]];
        }
    }];
    
    NSString* message = [messages componentsJoinedByString:@"\n"];
    return message;
}

@end
