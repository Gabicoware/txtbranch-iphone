//
//  LaunchViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "LaunchViewController.h"
#import "AuthenticationManager.h"
#import "AFHTTPSessionManager+txtbranch.h"

@implementation LaunchViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    if (![AuthenticationManager instance].isLoggedIn ) {
        [self getUserInfo];
    }
}

-(void)getUserInfo{
    
    __weak LaunchViewController* weakSelf = self;
    
    [[AFHTTPSessionManager currentManager] GET:@"/api/v1/userinfos"
                                    parameters:@{@"set_cookie":@"1"}
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
                                           if ([responseObject[@"status"] isEqualToString:@"OK"]) {
                                               [weakSelf.navigationController dismissViewControllerAnimated:YES completion:NULL];
                                           }else{
                                               [weakSelf performSegueWithIdentifier:@"Login" sender:self];
                                           }
                                       } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [weakSelf performSegueWithIdentifier:@"Login" sender:self];
                                       }];
    
}

@end
