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
#import "Config.h"


@interface LoginTableViewController ()

@end

@implementation LoginTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;

}

-(IBAction)didTapCancelButton:(id)sender{
    [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSArray*)authenticationProviders{
    return [Config currentConfig].data[@"authentication_providers"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self authenticationProviders].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary* provider = [self authenticationProviders][indexPath.row];
    cell.textLabel.text = provider[@"name"];
    
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
    
    NSDictionary* provider = [self authenticationProviders][indexPath.row];
    NSString* signInPath = provider[@"endpoint"];
    
    ((SignInViewController*)segue.destinationViewController).signInURL = [NSURL tbURLWithPath:signInPath];
}


@end
