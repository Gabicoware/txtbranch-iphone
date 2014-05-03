//
//  ViewController.h
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "txtbranch.h"

@interface BranchViewController : UIViewController<Queryable>

@property (nonatomic,copy) NSDictionary* query;

@end
