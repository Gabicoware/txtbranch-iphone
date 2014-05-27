//
//  BranchTableViewCell.h
//  txtbranch
//
//  Created by Daniel Mueller on 3/3/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkTableViewCell : UITableViewCell

@property (nonatomic,assign) BOOL isLink;

@property (nonatomic,strong) IBOutlet UILabel* linkLabel;

@end

@interface ContentTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel* contentLabel;

@end


@interface AboutTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel* aboutLabel;

@property (nonatomic,strong) IBOutlet UILabel* titleLabel;

@property (nonatomic,strong) IBOutlet UILabel* hintLabel;

@property (nonatomic,strong) IBOutlet UIView* footerView;

@property (nonatomic,assign) BOOL isAboutHidden;

@end

@interface AddBranchTableViewCell : UITableViewCell

@end

