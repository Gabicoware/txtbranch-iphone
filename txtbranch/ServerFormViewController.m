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

enum {
    InfoSection,
    SoftwareSection,
    DeleteSection,
    AddTotalSections=2,
    EditTotalSections=3,
};



@interface ServerFormViewController ()

@property (nonatomic, strong) IBOutlet UITextField* nameTextField;
@property (nonatomic, strong) IBOutlet UITextField* addressTextField;

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

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0 || (indexPath.section == 1 && indexPath.row == 0)) {
        return nil;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1 && indexPath.row == 1) {
        UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cell.textLabel.text]];
    }else if(indexPath.section == 2 && indexPath.row == 0){
        [[[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Are you sure you want to delete this server?"             cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@[@"OK"]
                                      block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                          if (buttonIndex == 1) {
                                              [[ServerList instance] removeServer:self.server];
                                              [[AuthenticationManager instance] resetForServer:self.server[@"address"]];
                                              [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
                                          }
                                      }] show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.server != nil) {
        return 3;
    }else{
        return 2;
    }
}


@end
