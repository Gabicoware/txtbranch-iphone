//
//  AboutTreeViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 7/15/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AboutTreeViewController.h"

@interface AboutTreeViewController ()

@property (nonatomic, weak) IBOutlet UITextView* textView;

@end

@implementation AboutTreeViewController

@synthesize query=_query;

-(void)viewDidLoad{
    [super viewDidLoad];
    self.textView.text = self.query[@"about"];
}

@end
