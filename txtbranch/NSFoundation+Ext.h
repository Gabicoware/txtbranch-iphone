//
//  NSFoundation+Ext.h
//  txtbranch
//
//  Created by Daniel Mueller on 9/25/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary(Merge)

-(NSDictionary*)dictionaryByMergingValues:(NSDictionary*)values;

@end

@interface NSDictionary (NullRemoval)

- (NSDictionary *)dictionaryByRemovingNulls;

@end

@interface NSArray (NullRemoval)

- (NSArray *)arrayByRemovingNulls;

@end
