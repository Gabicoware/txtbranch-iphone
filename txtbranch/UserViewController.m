//
//  UserViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/27/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UserViewController.h"
#import "AuthenticationManager.h"
#import "ServerList.h"
#import "UIAlertView+Block.h"

@interface UserViewController()

@property (nonatomic, strong) NSArray* sections;

@property (nonatomic, strong) IBOutlet UIBarButtonItem* signOutItem;

@end

@implementation UserViewController

@synthesize query=_query;

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self buildSections];
    [self.tableView reloadData];
    
    
}

-(BOOL)isAuthenticatedUser{
    return [self.query[@"username"] isEqualToString:[[AuthenticationManager instance] username]];
}

-(void)setQuery:(NSDictionary *)query{
    _query = query;
    [self buildSections];
    
    [self.tableView reloadData];
}

-(IBAction)didTapSignOutButton:(id)sender{
    
    [[[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you want to sign out?"
                     cancelButtonTitle:@"No" otherButtonTitles:@[@"Yes"] block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                         if (buttonIndex > 0) {
                             [[AuthenticationManager instance] clearCurrentSession];
                             [self buildSections];
                             
                             [self.tableView reloadData];
                         }
        
    }] show];
    
}

-(void)buildSections{
    
    if ([self isAuthenticatedUser]) {
        self.navigationItem.rightBarButtonItem = self.signOutItem;
    }else{
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.sections = @[@{@"text":@"Activity",@"segue":@"Notifications",@"query":@{@"from_username":self.query[@"username"]}},
                      @{@"text":@"Trees",@"segue":@"TreesView",@"query":@{@"username":self.query[@"username"]}}];
    
    if ([self isAuthenticatedUser]) {
        self.sections = [@[@{@"text":@"Inbox",@"detailText":[AuthenticationManager unreadCountString],@"segue":@"Inbox",@"query":@{}}] arrayByAddingObjectsFromArray:self.sections];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.sections.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"SectionCell"];
    
    NSDictionary* section = self.sections[indexPath.row];
    
    cell.textLabel.text = section[@"text"];
    
    if (section[@"detailText"]) {
        cell.detailTextLabel.text = section[@"detailText"];
    }else{
        cell.detailTextLabel.text = @"";
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary* section = self.sections[indexPath.row];
    
    [self performSegueWithIdentifier:section[@"segue"] sender:[tableView cellForRowAtIndexPath:indexPath]];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
    NSDictionary* section = self.sections[indexPath.row];
    UIViewController<Queryable>* controller = segue.destinationViewController;
    controller.title = section[@"text"];
    controller.query = section[@"query"];
    
}



@end
