//
//  BranchTableViewCell.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TBTextView.h"
#import "TTTAttributedLabel.h"

@interface BranchTableViewCell : UITableViewCell

@property (nonatomic,assign) BOOL isLink;

@property (nonatomic,strong) IBOutlet UILabel* linkLabel;
@property (nonatomic,strong) IBOutlet UILabel* contentLabel;

@end


@interface AboutTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel* aboutLabel;

@property (nonatomic,strong) IBOutlet UILabel* titleLabel;

@property (nonatomic,strong) IBOutlet UILabel* hintLabel;

@property (nonatomic,strong) IBOutlet UIView* footerView;

@property (nonatomic,assign) BOOL isAboutHidden;

@end

@interface LinkTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel* linkLabel;

@end

@interface AddBranchTableViewCell : UITableViewCell

@end

//for when the size of the cell needs to update
extern NSString* AddBranchFormTableViewCellUpdateSizeNotification;
extern NSString* AddBranchFormTableViewCellSaveNotification;
extern NSString* AddBranchFormTableViewCellCancelNotification;

@interface AddBranchFormTableViewCell : UITableViewCell<UITextViewDelegate>

@property (nonatomic,weak) IBOutlet TBTextView* linkTextView;
@property (nonatomic,weak) IBOutlet TBTextView* contentTextView;
@property (nonatomic,weak) IBOutlet UILabel* countLabel;
@property (nonatomic,weak) IBOutlet UIButton* saveButton;

-(void)setupWithBranch:(id)branch;

@property (nonatomic,assign) NSUInteger linkMax;
@property (nonatomic,assign) NSUInteger contentMax;

@end

@interface BranchMetadataTableViewCell : UITableViewCell

@property (nonatomic,weak) IBOutlet TTTAttributedLabel* deleteButton;
@property (nonatomic,weak) IBOutlet TTTAttributedLabel* editButton;
@property (nonatomic,weak) IBOutlet TTTAttributedLabel* bylineLabel;

@end



