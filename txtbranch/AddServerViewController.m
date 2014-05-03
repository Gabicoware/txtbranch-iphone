//
//  AddServerViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/25/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AddServerViewController.h"
#import "ServerList.h"

@interface AddServerViewController ()

@property (nonatomic, strong) IBOutlet UITextField* nameTextField;
@property (nonatomic, strong) IBOutlet UITextField* addressTextField;

@end

@implementation AddServerViewController

-(IBAction)didTapCancelButton:(id)sender{
    [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}

-(IBAction)didTapDoneButton:(id)sender{
    
    NSURL* url = [NSURL URLWithString:self.addressTextField.text];
    
    if (url != nil ) {
        
        [[ServerList instance] addServer:@{@"name":self.nameTextField.text,@"address":self.addressTextField.text}];
        
        [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
    }else{
        [[[UIAlertView alloc] initWithTitle:@"Invalid address"
                                    message:@"Addresses should be in the format \"http://example.com/\""
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles: nil] show];
    }
    
}

-(IBAction)didTapGithubButton:(id)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[sender titleForState:UIControlStateNormal]]];
}

@end
