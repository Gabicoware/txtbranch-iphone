//
//  UIAlertView+Block.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/20/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UIAlertView+Block.h"
#import <objc/runtime.h>

static const void *UIAlertViewCompletionBlockKey = &UIAlertViewCompletionBlockKey;

#define title(index,array) ( index < array.count ? array[index] : nil )

@implementation UIAlertView (Block)

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                        block:(UIAlertViewCompletionBlock)block{
    
    self = [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:
                              title(0,otherButtonTitles),
                              title(1,otherButtonTitles),
                              title(2,otherButtonTitles),
                              title(3,otherButtonTitles),
                              title(4,otherButtonTitles),
                              title(5,otherButtonTitles),
                              title(6,otherButtonTitles),
                              title(7,otherButtonTitles),
                              title(8,otherButtonTitles),
                              title(9,otherButtonTitles),
                              title(10,otherButtonTitles), nil];
    self.block = block;
    return self;
}

- (UIAlertViewCompletionBlock)block {
    return objc_getAssociatedObject(self, UIAlertViewCompletionBlockKey);
}

- (void)setBlock:(UIAlertViewCompletionBlock)tapBlock {
    objc_setAssociatedObject(self, UIAlertViewCompletionBlockKey, tapBlock, OBJC_ASSOCIATION_COPY);
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    UIAlertViewCompletionBlock block = self.block;
    block(self,buttonIndex);
}


@end
