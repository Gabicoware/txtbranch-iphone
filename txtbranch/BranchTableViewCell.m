//
//  BranchTableViewCell.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchTableViewCell.h"

@implementation ContentTableViewCell

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize result = self.frame.size;
    
    CGSize contentSize = [self.contentLabel sizeThatFits:self.contentLabel.frame.size];
    result.height = contentSize.height;
    
    return result;
}

@end

#define LinkHeight(height) MAX(height, 26.0)

@implementation LinkTableViewCell

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize result = self.frame.size;
    
    CGSize linkLabelSize = [self.linkLabel sizeThatFits:self.linkLabel.frame.size];
    if (self.accessoryType == UITableViewCellAccessoryDetailButton) {
        result.height = LinkHeight(linkLabelSize.height);
    }else{
        result.height = linkLabelSize.height;
    }
    
    return result;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    CGSize linkLabelSize = [self.linkLabel sizeThatFits:self.linkLabel.frame.size];
    CGRect linkRect = self.linkLabel.frame;
    if (self.accessoryType == UITableViewCellAccessoryDetailButton) {
        linkRect.size.height = LinkHeight(linkLabelSize.height);
    }else{
        linkRect.size.height = linkLabelSize.height;
    }
    self.linkLabel.frame = linkRect;
    
}

-(void)setIsLink:(BOOL)isLink{
    if (isLink != _isLink) {
        _isLink = isLink;
        if (isLink) {
            self.accessoryType = UITableViewCellAccessoryNone;
        }else{
            self.accessoryType = UITableViewCellAccessoryDetailButton;
        }
        [self layoutSubviews];
    }
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
