//
//  QueryableList.h
//  txtbranch
//
//  Created by Daniel Mueller on 6/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "txtbranch.h"

@interface QueryableList : NSObject<Queryable>

@property (nonatomic, strong) NSString* basePath;

@property (nonatomic, strong) NSArray* items;

//does not load inifite items
-(void)refresh;

@end
