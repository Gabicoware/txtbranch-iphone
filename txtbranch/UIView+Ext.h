//
//  UIView+Ext.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/27/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Ext)

-(id)recursiveDescription;

+(NSString*)dump;

@end