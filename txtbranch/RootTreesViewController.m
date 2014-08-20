//
//  RootTreesViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "RootTreesViewController.h"
#import "AuthenticationManager.h"
#import "NSURL+txtbranch.h"
#import "Config.h"
#import "Messages.h"

@interface RootTreesViewController ()

@property (nonatomic, strong) NSArray* sections;

@property (nonatomic, strong) IBOutlet UIBarButtonItem* signInItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* addTreeItem;

@end

@implementation RootTreesViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleInboxUnreadCountDidUpdateNotification:(NSNotification*)notification{
    [self buildSections];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInboxUnreadCountDidUpdateNotification:) name:InboxUnreadCountDidUpdate object:nil];
    
    [super viewDidLoad];
    self.title = [NSURL tbURLName];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenTreeNotification:) name:@"OpenTree" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataAssetDidLoad:) name:DataAssetDidLoad object:[Config currentConfig]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        //we reload these every time if the application is active
        [[Config currentConfig] reloadData];
        [[Messages currentMessages] reloadData];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [self buildSections];
    [super viewWillAppear:animated];
    if ([AuthenticationManager instance].isLoggedIn) {
        self.navigationItem.rightBarButtonItem = self.addTreeItem;
    }else{
        self.navigationItem.rightBarButtonItem = self.signInItem;
    }
}

-(void)handleDataAssetDidLoad:(NSNotification*)notification{
    if ([Config currentConfig].data) {
        [super refresh];
    }else{
        [[[UIAlertView alloc] initWithTitle:@"Can't connect to server" message:@"There was an error reaching the server. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        [self.refreshControl endRefreshing];
    }
}

-(void)handleOpenTreeNotification:(NSNotification*)notification{
    [self performSegueWithIdentifier:@"OpenTree" sender:notification.object];
}

-(void)handleApplicationDidBecomeActiveNotification:(NSNotification*)notification{
    [[Config currentConfig] reloadData];
    [[Messages currentMessages] reloadData];
}

-(void)buildSections{
    if ([[AuthenticationManager instance] isLoggedIn]) {
        self.sections = @[@{@"text":[[AuthenticationManager instance] username],
                            @"detailText":[AuthenticationManager  unreadCountString],
                            @"identifier":@"UsernameCell",
                            @"query":@{@"username":[[AuthenticationManager instance] username]}}];
    }else{
        self.sections = @[];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)refresh{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        if ([Config currentConfig].data) {
            [[[AuthenticationManager instance] inbox] refresh];
            [super refresh];
        }else{
            [[Config currentConfig] reloadData];
            [[Messages currentMessages] reloadData];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.sections.count;
    }else{
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        NSDictionary* section = self.sections[indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:section[@"identifier"] forIndexPath:indexPath];
        if (section[@"text"]) {
            cell.textLabel.text = section[@"text"];
        }
        if (section[@"detailText"]) {
            cell.detailTextLabel.text = section[@"detailText"];
        }
    }else if (indexPath.section == 1) {
        cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return nil;
    }else{
        return @"Trees";
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"UserView"]) {
        
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        NSDictionary* section = self.sections[indexPath.row];
        UIViewController<Queryable>* controller = segue.destinationViewController;
        controller.title = section[@"text"];
        controller.query = section[@"query"];
        
    }
    
}

@end