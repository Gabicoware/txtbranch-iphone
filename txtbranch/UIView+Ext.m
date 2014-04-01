//
//  UIView+Ext.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/27/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UIView+Ext.h"

@implementation UIView (Ext)

+(NSString*)dump{
    return [[[UIApplication sharedApplication] keyWindow] recursiveDescription];
}

@end
