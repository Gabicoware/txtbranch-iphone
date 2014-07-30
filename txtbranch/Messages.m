//
//  Messages.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "Messages.h"
#import "NSURL+txtbranch.h"

@implementation Messages

+(NSString*)path{
    return @"/messages.json";
}

+(instancetype)currentMessages{
    return [self currentAsset];
}

-(NSString*)errorMessageForResult:(NSArray*)errors{
    NSMutableArray* messages = [NSMutableArray array];
    
    [errors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (self.data[obj]) {
            [messages addObject:self.data[obj]];
        }
    }];
    
    NSString* message = [messages componentsJoinedByString:@"\n\n"];
    return message;
}

-(NSString*)requestFailureMessage{
    return @"There was an error contacting the server. Please check your connectivity and try again.";
}

-(NSString*)resetLoginTitle{
    return @"We're Sorry";
}
-(NSString*)resetLoginMessage{
    return @"You've been logged out. This is likely due to a bug we are scrambling to fix. Please log in again if you wish.";
}



@end
