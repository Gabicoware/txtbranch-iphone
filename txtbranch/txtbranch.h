//
//  txtbranch.h
//  txtbranch
//
//  Created by Daniel Mueller on 5/1/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Queryable <NSObject>

@property (nonatomic, copy) NSDictionary* query;

@end