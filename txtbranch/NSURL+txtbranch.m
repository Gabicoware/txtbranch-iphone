//
//  NSURL+txtbranch.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "NSURL+txtbranch.h"
#import "ServerList.h"

@implementation NSURL (txtbranch)

+(NSString*)tbURLName{
    return [[ServerList instance] activeServer][@"name"];
}

+(NSURL*)tbURLWithPath:(NSString*)path{
    
    NSString* address = [[ServerList instance] activeServer][@"address"];
    
    NSMutableCharacterSet* characters = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
    
    [characters addCharactersInString:@"/"];
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[address stringByTrimmingCharactersInSet:characters],path]];
}

+(NSURL*)tbURL{
    return [NSURL tbURLWithPath:@""];
}
@end
