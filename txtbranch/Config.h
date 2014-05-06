//
//  Config.h
//  txtbranch
//
//  Created by Daniel Mueller on 5/5/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* ConfigDidLoad;

@interface Config : NSObject

+(instancetype)currentConfig;

-(NSString*)errorMessageForResult:(id)result;

@property (nonatomic, copy) NSDictionary* data;

-(void)reloadData;

@end
