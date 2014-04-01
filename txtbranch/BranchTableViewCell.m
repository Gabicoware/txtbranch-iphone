//
//  BranchTableViewCell.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchTableViewCell.h"

@implementation BranchTableViewCell

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize selfSize = self.frame.size;
    
    CGSize linkSize = [self.linkLabel sizeThatFits:self.linkLabel.frame.size];
    CGFloat linkHeightDiff = linkSize.height - self.linkLabel.frame.size.height;
    
    selfSize.height += linkHeightDiff;
    
    CGSize contentSize = [self.contentLabel sizeThatFits:self.contentLabel.frame.size];
    CGFloat contentHeightDiff = contentSize.height - self.contentLabel.frame.size.height;
    
    selfSize.height += contentHeightDiff;
    
    return selfSize;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGSize linkSize = [self.linkLabel sizeThatFits:self.linkLabel.frame.size];
    CGFloat linkHeightDiff = linkSize.height - self.linkLabel.frame.size.height;
    
    CGRect linkRect = self.linkLabel.frame;
    linkRect.size.height += linkHeightDiff;
    self.linkLabel.frame = linkRect;
    
    CGSize contentSize = [self.contentLabel sizeThatFits:self.contentLabel.frame.size];
    CGFloat contentHeightDiff = contentSize.height - self.contentLabel.frame.size.height;
    
    CGRect contentRect = self.contentLabel.frame;
    contentRect.origin.y += linkHeightDiff;
    contentRect.size.height += contentHeightDiff;
    self.contentLabel.frame = contentRect;
    
}


@end


@implementation AboutTableViewCell

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize selfSize = self.frame.size;
    
    if (self.isAboutHidden) {
        selfSize.height = self.titleLabel.frame.size.height;
    }else{
        CGSize size = [self.aboutLabel sizeThatFits:self.aboutLabel.frame.size];
        CGFloat heightDiff = size.height - self.aboutLabel.frame.size.height;
        selfSize.height += heightDiff;
    }
    
    return selfSize;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGSize size = [self.aboutLabel sizeThatFits:self.aboutLabel.frame.size];
    CGRect aboutRect = self.aboutLabel.frame;
    aboutRect.size.height = size.height;
    self.aboutLabel.frame = aboutRect;
    
    CGRect footerRect = self.footerView.frame;
    footerRect.origin.y = CGRectGetMaxY(aboutRect);
    self.footerView.frame = footerRect;
    
}

-(void)setIsAboutHidden:(BOOL)isAboutHidden{
    _isAboutHidden = isAboutHidden;
    if (isAboutHidden) {
        self.hintLabel.text = NSLocalizedString(@"tap to show", nil);
    }else{
        self.hintLabel.text = NSLocalizedString(@"tap to hide", nil);
    }
}

@end

@implementation LinkTableViewCell

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize selfSize = self.frame.size;
    
    CGSize linkLabelSize = [self.linkLabel sizeThatFits:self.linkLabel.frame.size];
    CGFloat heightDiff = linkLabelSize.height - self.linkLabel.frame.size.height;
    selfSize.height += heightDiff;
    
    return selfSize;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGSize linkLabelSize = [self.linkLabel sizeThatFits:self.linkLabel.frame.size];
    CGRect aboutRect = self.linkLabel.frame;
    aboutRect.size.height = linkLabelSize.height;
    self.linkLabel.frame = aboutRect;
    
}

@end

@implementation AddBranchTableViewCell

@end

NSString* AddBranchFormTableViewCellUpdateSizeNotification = @"AddBranchFormTableViewCellUpdateSizeNotification";
NSString* AddBranchFormTableViewCellSaveNotification = @"AddBranchFormTableViewCellSaveNotification";
NSString* AddBranchFormTableViewCellCancelNotification = @"AddBranchFormTableViewCellCancelNotification";

static NSString* ContentText = nil;
static NSString* LinkText = nil;

@implementation AddBranchFormTableViewCell

-(IBAction)didTapCancelButton:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:AddBranchFormTableViewCellCancelNotification object:self];
}

-(IBAction)didTapSaveButton:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:AddBranchFormTableViewCellSaveNotification object:self];
}

-(CGSize)sizeThatFits:(CGSize)size{
    if (![self.linkTextView.text isEqualToString:LinkText]) {
        self.linkTextView.text = LinkText;
        [self.linkTextView layoutSubviews];
    }
    if (![self.contentTextView.text isEqualToString:ContentText]) {
        self.contentTextView.text = ContentText;
        [self.contentTextView layoutSubviews];
    }
    
    CGSize selfSize = self.frame.size;
    
    CGFloat linkHeightDiff = 0.0;
    if (![self.linkTextView.text isEqualToString:@""]) {
        linkHeightDiff = self.linkTextView.contentSize.height - self.linkTextView.frame.size.height;
    }
    
    CGFloat contentHeightDiff = 0.0;
    if (![self.contentTextView.text isEqualToString:@""]) {
        contentHeightDiff = self.contentTextView.contentSize.height - self.contentTextView.frame.size.height;
    }
    
    selfSize.height += linkHeightDiff;
    selfSize.height += contentHeightDiff;
    
    return selfSize;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (![self.linkTextView.text isEqualToString:LinkText]) {
        self.linkTextView.text = LinkText;
        [self.linkTextView layoutSubviews];
    }
    if (![self.contentTextView.text isEqualToString:ContentText]) {
        self.contentTextView.text = ContentText;
        [self.contentTextView layoutSubviews];
    }
    
    CGRect linkTextViewFrame = self.linkTextView.frame;
    
    CGFloat linkHeightDiff = 0.0;
    if (![self.linkTextView.text isEqualToString:@""]) {
        linkHeightDiff = self.linkTextView.contentSize.height - self.linkTextView.frame.size.height;
    }
    
    CGFloat contentHeightDiff = 0.0;
    CGRect contentTextViewFrame = self.contentTextView.frame;
    if (![self.contentTextView.text isEqualToString:@""]) {
        contentHeightDiff = self.contentTextView.contentSize.height - self.contentTextView.frame.size.height;
    }
    contentTextViewFrame.origin.y = contentTextViewFrame.origin.y + linkHeightDiff;
    contentTextViewFrame.size.height = contentTextViewFrame.size.height + contentHeightDiff;
    linkTextViewFrame.size.height = linkTextViewFrame.size.height + linkHeightDiff;
    
    self.linkTextView.frame = linkTextViewFrame;
    self.contentTextView.frame = contentTextViewFrame;
    
}

-(void)setupWithBranch:(id)branch{
    LinkText = branch[@"link"];
    ContentText = branch[@"content"];
}

-(void)willMoveToWindow:(UIWindow *)newWindow{
    [super willMoveToWindow:newWindow];
    if (newWindow != nil) {
        [self setNeedsLayout];
    }
}

-(void)prepareForReuse{
    [super prepareForReuse];
    LinkText = @"";
    ContentText = @"";
    self.linkTextView.text = @"";
    self.contentTextView.text = @"";
}

-(void)awakeFromNib{
    [super awakeFromNib];
    self.linkTextView.placeholder = @"Add a teaser...";
    self.contentTextView.placeholder = @"...and continue with some more text";
}

- (void)textViewDidChange:(UITextView *)textView{
    
    CGFloat linkHeightDiff = 0.0;
    if (![self.linkTextView.text isEqualToString:@""]) {
        linkHeightDiff = self.linkTextView.contentSize.height - self.linkTextView.frame.size.height;
    }
    
    CGFloat contentHeightDiff = 0.0;
    if (![self.contentTextView.text isEqualToString:@""]) {
        contentHeightDiff = self.contentTextView.contentSize.height - self.contentTextView.frame.size.height;
    }
    
    if (0 != contentHeightDiff || 0 != linkHeightDiff) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AddBranchFormTableViewCellUpdateSizeNotification object:self];
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([textView isEqual:self.linkTextView]) {
        LinkText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    }else if ([textView isEqual:self.contentTextView]) {
        ContentText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    }
    return YES;
}

@end

@implementation BranchMetadataTableViewCell

@end


