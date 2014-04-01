//
//  LoginTableViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/7/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "LoginTableViewController.h"
#import "SignInViewController.h"
#import "NSURL+txtbranch.h"

typedef enum _LoginServices {
#if LOCAL
    LoginServicesLocalhost,
#endif
    LoginServicesTwitter,
    LoginServicesFacebook,
    LoginServicesReddit,
    LoginServicesCount,
} LoginServices;


@interface LoginTableViewController ()

@end

@implementation LoginTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;

}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return LoginServicesCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    switch (indexPath.row) {
#if LOCAL
        case LoginServicesLocalhost:
            cell.textLabel.text = @"Localhost";
            break;
#endif
        case LoginServicesTwitter:
            cell.textLabel.text = @"Twitter";
            break;
        case LoginServicesFacebook:
            cell.textLabel.text = @"Facebook";
            break;
        case LoginServicesReddit:
            cell.textLabel.text = @"Reddit";
            break;
            
        default:
            break;
    }
    
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    NSDictionary* signInPaths = @{
#if LOCAL
                           @(LoginServicesLocalhost): @"/google_login",
#endif
                           @(LoginServicesTwitter): @"/auth/twitter",
                           @(LoginServicesFacebook): @"/auth/facebook",
                           @(LoginServicesReddit): @"/auth/reddit"
                           };
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
    
    NSString* signInPath = signInPaths[@(indexPath.row)];
    
    ((SignInViewController*)segue.destinationViewController).signInURL = [NSURL tbURLWithPath:signInPath];
}


@end
