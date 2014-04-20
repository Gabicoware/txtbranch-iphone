//
//  TreesViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/5/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "TreesViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSURL+txtbranch.h"
#import "BranchViewController.h"
#import "AuthenticationManager.h"
#import "NotificationsTableViewController.h"
#import "AuthenticationManager.h"

@interface TreesViewController ()

@property (nonatomic,strong) ASIHTTPRequest* request;

@property (nonatomic, strong) NSArray* trees;
@property (nonatomic, strong) NSArray* sections;

@end

@implementation TreesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"txtbranch";

    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self action:@selector(loadMainTrees)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.refreshControl beginRefreshing];
    
    [self loadMainTrees];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(didTapLoginButton:)];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self buildSections];
    [self.tableView reloadData];
}

-(BOOL)hasActivityOrInbox{
    return [[AuthenticationManager instance] isLoggedIn];
}

-(void)buildSections{
    if ([self hasActivityOrInbox]) {
        self.sections = @[@{@"text":@"Inbox",@"identifier":@"NotificationSectionCell"},
                          @{@"text":@"Activity",@"identifier":@"NotificationSectionCell",
                            @"query":@{@"from_username":[[AuthenticationManager instance] username]}}];
    }else{
        self.sections = @[];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)didTapLoginButton:(id)sender{
    if (![AuthenticationManager instance].isLoggedIn) {
        [self performSegueWithIdentifier:@"Login" sender:self];
    }
}

-(void)loadMainTrees{
    [_request cancel];
    
    NSURL* URL = [NSURL tbURLWithPath:@"/api/v1/trees?list=main"];
    
	[self setRequest:[ASIHTTPRequest requestWithURL:URL]];
	[_request setTimeOutSeconds:20];
    
	[_request setDelegate:self];
	[_request setDidFailSelector:@selector(listRequestFailed:)];
	[_request setDidFinishSelector:@selector(listRequestFinished:)];
	
	[_request startAsynchronous];
}

-(void)listRequestFinished:(ASIHTTPRequest*)request{
    [self.refreshControl endRefreshing];
    
    
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        self.trees = result[@"result"];
        [self.tableView reloadData];
    }
}

-(void)listRequestFailed:(ASIHTTPRequest*)sender{
    [self.refreshControl endRefreshing];
    NSLog(@"");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        return self.trees.count;
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
    }else if (indexPath.section == 1) {
        static NSString *TreeCellIdentifier = @"TreeTableViewCell";
        cell = [tableView dequeueReusableCellWithIdentifier:TreeCellIdentifier forIndexPath:indexPath];
        
        NSDictionary* tree = [self.trees objectAtIndex:indexPath.row];
        
        cell.textLabel.text = tree[@"name"];
        cell.detailTextLabel.text = tree[@"moderator_name"];
        
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
    if ([segue.identifier isEqualToString:@"OpenTree"]) {
        BranchViewController* controller = (BranchViewController*)segue.destinationViewController;
        NSDictionary* query = @{@"tree_name":((UITableViewCell*)sender).textLabel.text};
        controller.query = query;
    }
    if ([segue.identifier isEqualToString:@"OpenNotifications"]) {
        
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        NSDictionary* section = self.sections[indexPath.row];
        NotificationsTableViewController* controller = segue.destinationViewController;
        controller.title = section[@"text"];
        controller.query = section[@"query"];
        
    }
    
}

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self hasActivityOrInbox] && indexPath.section == 0) {
        return nil;
    }
    return indexPath;
}

@end
