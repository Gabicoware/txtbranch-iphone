//
//  LaunchViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "LaunchViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSURL+txtbranch.h"
#import "SignInViewController.h"
#import "AuthenticationManager.h"

@interface LaunchViewController ()

@property (nonatomic,strong) ASIHTTPRequest* request;

@end

@implementation LaunchViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    if (![AuthenticationManager instance].isLoggedIn ) {
        [self getUserInfo];
    }
}

-(void)getUserInfo{
    
    NSURL* URL = [NSURL tbURLWithPath:@"/api/v1/userinfos?set_cookie=1"];
    
    [self setRequest:[ASIHTTPRequest requestWithURL:URL]];
    [_request setTimeOutSeconds:3];
    
    [_request setDelegate:self];
    [_request setDidFailSelector:@selector(userinfoRequestFailed:)];
    [_request setDidFinishSelector:@selector(userinfoRequestFinished:)];
    _request.cachePolicy = ASIDoNotReadFromCacheCachePolicy;
    [_request startAsynchronous];
    
}

-(void)userinfoRequestFinished:(ASIHTTPRequest*)request{
    
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }else{
        [self performSegueWithIdentifier:@"Login" sender:self];
    }
}

-(void)userinfoRequestFailed:(ASIHTTPRequest*)request{
    [self performSegueWithIdentifier:@"Login" sender:self];
}

@end
