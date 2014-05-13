//
//  ServerFormViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/25/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "ServerFormViewController.h"
#import "ServerList.h"
#import "UIAlertView+Block.h"
#import "AuthenticationManager.h"

@interface ServerFormViewController ()

@property (nonatomic, strong) IBOutlet UITextField* nameTextField;
@property (nonatomic, strong) IBOutlet UITextField* addressTextField;
@property (nonatomic, strong) IBOutlet UIButton* deleteButton;

@end

@implementation ServerFormViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self updateFields];
}

-(void)setServer:(NSDictionary*)server{
    _server = server;
    if (server == nil) {
        self.title = @"Add a Server";
    }else{
        self.title = server[@"name"];
    }
    [self updateFields];
}

-(void)updateFields{
    self.nameTextField.text = self.server[@"name"];
    self.addressTextField.text = self.server[@"address"];
    self.deleteButton.hidden = self.server == nil;
}

-(IBAction)didTapCancelButton:(id)sender{
    [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}

-(IBAction)didTapDoneButton:(id)sender{
    
    NSURL* url = [NSURL URLWithString:self.addressTextField.text];
    
    if (url != nil ) {
        
        if (self.server != nil) {
            [[ServerList instance] removeServer:self.server];
        }
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

-(IBAction)didTapDeleteServerButton:(id)sender{
    [[[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Are you sure you want to delete this server?"             cancelButtonTitle:@"Cancel"
                     otherButtonTitles:@[@"OK"]
                                 block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                     if (buttonIndex == 1) {
                                         [[ServerList instance] removeServer:self.server];
                                         [[AuthenticationManager instance] clearCookiesForServer:self.server[@"address"]];
                                         [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
                                     }
                                 }] show];

}


@end
