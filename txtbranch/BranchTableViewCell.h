//
//  BranchTableViewCell.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TBTextView.h"

@interface BranchTableViewCell : UITableViewCell

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

@end



