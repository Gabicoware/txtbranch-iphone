//
//  UsernameViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UsernameViewController.h"

@interface UsernameViewController ()

@property (nonatomic,weak) IBOutlet UITextField* usernameTextField;


@end

@implementation UsernameViewController

-(void)viewDidLoad{
    
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didTapCancel:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didTapSave:)];
}

-(void)didTapCancel:(id)sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

-(void)didTapSave:(id)sender{
    
    NSString* username = self.usernameTextField.text;
    
    NSError* error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^[\\d\\w_\\-]+$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSRange range = [regex rangeOfFirstMatchInString:username
                                             options:NSMatchingReportProgress
                                               range:NSMakeRange(0, username.length)];
    
    if (range.location == 0 && 4 <= username.length && username.length <= 20) {
        [[[UIAlertView alloc] initWithTitle:@"Nice" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles: nil] show];
    }else{
        
        
    }
}



@end