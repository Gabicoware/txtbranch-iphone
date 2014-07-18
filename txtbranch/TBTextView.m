//
//  TBTextView.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "TBTextView.h"


@interface TBTextView ()

@property (nonatomic, retain) UILabel *placeHolderLabel;

@end

#define PLACEHOLDER_TAG 10001

@implementation TBTextView

CGFloat const UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION = 0.25;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if __has_feature(objc_arc)
#else
    [_placeHolderLabel release]; _placeHolderLabel = nil;
    [_placeholderColor release]; _placeholderColor = nil;
    [_placeholder release]; _placeholder = nil;
    [super dealloc];
#endif
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Use Interface Builder User Defined Runtime Attributes to set
    // placeholder and placeholderColor in Interface Builder.
    if (!self.placeholder) {
        [self setPlaceholder:@""];
    }
    
    if (!self.placeholderColor) {
        [self setPlaceholderColor:[UIColor lightGrayColor]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    if( (self = [super initWithFrame:frame]) )
    {
        [self setPlaceholder:@""];
        [self setPlaceholderColor:[UIColor lightGrayColor]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)textChanged:(NSNotification *)notification
{
    if([[self placeholder] length] == 0)
    {
        return;
    }
    
    [UIView animateWithDuration:UI_PLACEHOLDER_TEXT_CHANGED_ANIMATION_DURATION animations:^{
        if([[self text] length] == 0)
        {
            [[self viewWithTag:PLACEHOLDER_TAG] setAlpha:1];
        }
        else
        {
            [[self viewWithTag:PLACEHOLDER_TAG] setAlpha:0];
        }
    }];
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self textChanged:nil];
}

- (void)drawRect:(CGRect)rect
{
    if( [[self placeholder] length] > 0 )
    {
        [self placeHolderLabel].text = self.placeholder;
        [[self placeHolderLabel] sizeToFit];
        [self sendSubviewToBack:_placeHolderLabel];
    }
    
    if( [[self text] length] == 0 && [[self placeholder] length] > 0 )
    {
        [[self viewWithTag:PLACEHOLDER_TAG] setAlpha:1];
    }
    
    [super drawRect:rect];
}

-(CGSize)placeholderSize{
    [self placeHolderLabel].text = self.placeholder;
    CGSize size = [[self placeHolderLabel] sizeThatFits:self.bounds.size];
    return CGSizeMake(size.width + self.placeHolderLabel.frame.origin.x, size.height + self.placeHolderLabel.frame.origin.y);
}

-(UILabel*)placeHolderLabel{
    if (_placeHolderLabel == nil )
    {
        _placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(8,8,self.bounds.size.width - 16,0)];
        _placeHolderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _placeHolderLabel.numberOfLines = 0;
        _placeHolderLabel.font = self.font;
        _placeHolderLabel.backgroundColor = [UIColor clearColor];
        _placeHolderLabel.textColor = self.placeholderColor;
        _placeHolderLabel.alpha = 0;
        _placeHolderLabel.tag = PLACEHOLDER_TAG;
        [self addSubview:_placeHolderLabel];
    }
    return _placeHolderLabel;
}

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize result = [super sizeThatFits:size];
    if ([self.text isEqualToString:@""]) {
        result.height = self.placeholderSize.height;
    }
    result.width = size.width;
    return result;
}

@end