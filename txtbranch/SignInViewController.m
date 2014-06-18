//
//  SignInViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/4/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "SignInViewController.h"
#import "NSURL+txtbranch.h"
#import "UsernameViewController.h"
#import "AuthenticationManager.h"
#import "AFHTTPSessionManager+txtbranch.h"

@interface SignInViewController ()<UIWebViewDelegate>

@property (nonatomic,weak) IBOutlet UIWebView* webView;

@property (nonatomic,strong) IBOutlet UIView* activityView;

@end

@implementation SignInViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    NSURLRequest* request = [NSURLRequest requestWithURL:self.signInURL];
    
    [self.webView loadRequest:request];
}

-(void)didTapCancel:(id)sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    if ([request.URL.path isEqualToString:@"/post_login"] || [request.URL.path isEqualToString:@"/"]) {
        //show nativeUI
        
        self.activityView.frame = self.view.bounds;
        
        [self.view addSubview:self.activityView];
        
        [self getUserInfo];
        
        webView.hidden = YES;
        
        return NO;
    }
    return YES;
}

-(void)getUserInfo{
    
    [self.view addSubview:self.activityView];
    
    __weak SignInViewController* weakSelf = self;
    
    [[AFHTTPSessionManager currentManager] GET:@"/api/v1/userinfos"
                                    parameters:@{@"set_cookie":@"1"}
                                       success:^(NSURLSessionDataTask *task, id result) {
                                           if ([result[@"status"] isEqualToString:@"OK"]) {
                                               
                                               [[AuthenticationManager instance] updateLoginState];
                                               [weakSelf.navigationController dismissViewControllerAnimated:YES completion:NULL];
                                           }else if([result[@"result"] containsObject:@"needs_username"]){
                                               [weakSelf showUsernameView];
                                           }else{
                                               //not a common scenario, but the best way to handle this is to dismiss the UI, and start again
                                               [[[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Could not login. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                               
                                               [weakSelf.navigationController dismissViewControllerAnimated:YES completion:NULL];
                                           }
                                       } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [self showUsernameView];
                                       }];
    
}

-(void)showUsernameView{
    [self performSegueWithIdentifier:@"CreateUsername" sender:self];
}

@end

