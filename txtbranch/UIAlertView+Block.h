//
//  UIAlertView+Block.h
//  txtbranch
//
//  Created by Daniel Mueller on 4/20/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^UIAlertViewCompletionBlock) (UIAlertView *alertView, NSInteger buttonIndex);

@interface UIAlertView (Block)

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                        block:(UIAlertViewCompletionBlock)block;

@property (copy, nonatomic) UIAlertViewCompletionBlock block;

@end
