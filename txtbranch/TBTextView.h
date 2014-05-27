//
//  TBTextView.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TBTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;
@property (nonatomic, readonly) CGSize placeholderSize;

-(void)textChanged:(NSNotification*)notification;

@end