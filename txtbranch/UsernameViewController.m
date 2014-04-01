//
//  UsernameViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UsernameViewController.h"
#import "NSURL+txtbranch.h"
#import "ASIFormDataRequest.h"
#import "AuthenticationManager.h"

@interface UsernameViewController ()

@property (nonatomic,weak) IBOutlet UITextField* usernameTextField;
@property (nonatomic,weak) ASIFormDataRequest* request;


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
        
        NSURL* URL = [NSURL tbURLWithPath:@"/api/v1/userinfos"];
        
        [self setRequest:[ASIFormDataRequest requestWithURL:URL]];
        
        [_request addPostValue:username forKey:@"username"];
        [_request setTimeOutSeconds:20];
        
        [_request setDelegate:self];
        [_request setDidFailSelector:@selector(userinfoRequestFailed:)];
        [_request setDidFinishSelector:@selector(userinfoRequestFinished:)];
        _request.cachePolicy = ASIDoNotReadFromCacheCachePolicy;
        [_request startAsynchronous];
        
    }else{
        
        
        
    }
}

-(void)userinfoRequestFinished:(ASIHTTPRequest*)request{
    
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        
        [AuthenticationManager instance].isLoggedIn = YES;
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }else{
        //[self showUsernameView];
    }
}

-(void)userinfoRequestFailed:(ASIHTTPRequest*)request{
    //[self showUsernameView];
}



@end