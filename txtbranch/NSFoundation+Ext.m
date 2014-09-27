//
//  NSFoundation+Ext.m
//  txtbranch
//
//  Created by Daniel Mueller on 9/25/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "NSFoundation+Ext.h"


@implementation NSDictionary (NullReplacement)

- (NSDictionary *)dictionaryByRemovingNulls {
    const NSMutableDictionary *replaced = [self mutableCopy];
    const id nul = [NSNull null];
    
    for (NSString *key in self) {
        id object = [self objectForKey:key];
        if (object == nul) [replaced removeObjectForKey:key];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced setObject:[object dictionaryByRemovingNulls] forKey:key];
        else if ([object isKindOfClass:[NSArray class]]) [replaced setObject:[object arrayByRemovingNulls] forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:[replaced copy]];
}

@end

@implementation NSArray (NullReplacement)

- (NSArray *)arrayByRemovingNulls  {
    NSMutableArray *replaced = [self mutableCopy];
    const id nul = [NSNull null];
    for (int idx = 0; idx < [replaced count]; idx++) {
        id object = [replaced objectAtIndex:idx];
        if (object == nul) [replaced removeObject:object];
        else if ([object isKindOfClass:[NSDictionary class]]) [replaced replaceObjectAtIndex:idx withObject:[object dictionaryByRemovingNulls]];
        else if ([object isKindOfClass:[NSArray class]]) [replaced replaceObjectAtIndex:idx withObject:[object arrayByRemovingNulls]];
    }
    return [replaced copy];
}

@end

@implementation NSDictionary(Merge)

-(NSDictionary*)dictionaryByMergingValues:(NSDictionary*)values{
    NSMutableDictionary* result = [self mutableCopy];
    for (id key in values) {
        if (values[key] != nil && ![values[key] isEqual:[NSNull null]]) {
            result[key] = values[key];
        }
    }
    return [result copy];
}


@end

