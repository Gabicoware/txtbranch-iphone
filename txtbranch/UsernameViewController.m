//
//  UsernameViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UsernameViewController.h"
#import "NSURL+txtbranch.h"
#import "AuthenticationManager.h"
#import "AFHTTPSessionManager+txtbranch.h"
#import "Messages.h"

@interface UsernameViewController ()<UITextFieldDelegate>

@property (nonatomic,weak) IBOutlet UITextField* usernameTextField;


@end

@implementation UsernameViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem.enabled = [self isValidUsername:self.usernameTextField.text];
}

-(IBAction)didTapCancel:(id)sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

-(IBAction)didTapSave:(id)sender{
    
    if ([self isValidUsername:self.usernameTextField.text]) {
        
        [[AFHTTPSessionManager currentManager] POST:@"/api/v1/userinfos" parameters:@{@"username":self.usernameTextField.text} success:^(NSURLSessionDataTask *task, id responseObject) {
            if ([responseObject[@"status"] isEqualToString:@"OK"]) {
                
                [[AuthenticationManager instance] updateLoginState];
                [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
            }else{
                NSString* message = [[Messages currentMessages] errorMessageForResult:responseObject[@"result"]];
                [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }

        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:[[Messages currentMessages] requestFailureMessage]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles: nil] show];
        }];
        
    }
}

-(BOOL)isValidUsername:(NSString*)username{
    
    NSError* error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^[\\d\\w_\\-]+$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSRange range = [regex rangeOfFirstMatchInString:username
                                             options:NSMatchingReportProgress
                                               range:NSMakeRange(0, username.length)];
    
    return range.location == 0 && 4 <= username.length && username.length <= 20;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString* username = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL isValid = [self isValidUsername:username];
    self.navigationItem.rightBarButtonItem.enabled = isValid;
    
    textField.textColor = isValid ? [UIColor blackColor] : [UIColor redColor];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self didTapSave:nil];
    return YES;
}


@end