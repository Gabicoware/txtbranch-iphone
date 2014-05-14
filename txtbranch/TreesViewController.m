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
#import "NSURL+txtbranch.h"
#import "Config.h"
#import "Messages.h"

@interface TreesViewController ()

@property (nonatomic,strong) ASIHTTPRequest* request;

@property (nonatomic, strong) NSArray* trees;
@property (nonatomic, strong) NSArray* sections;

@property (nonatomic, strong) IBOutlet UIBarButtonItem* signInItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* addTreeItem;

@end

@implementation TreesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSURL tbURLName];

    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.refreshControl beginRefreshing];
    
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOpenTreeNotification:) name:@"OpenTree" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataAssetDidLoad:) name:DataAssetDidLoad object:[Config currentConfig]];
    
    //we reload these every time
    [[Config currentConfig] reloadData];
    [[Messages currentMessages] reloadData];
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.request cancel];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self buildSections];
    [self.tableView reloadData];
    if ([AuthenticationManager instance].isLoggedIn) {
        self.navigationItem.rightBarButtonItem = self.addTreeItem;
    }else{
        self.navigationItem.rightBarButtonItem = self.signInItem;
    }
}

-(void)handleDataAssetDidLoad:(NSNotification*)notification{
    if ([Config currentConfig].data) {
        [self loadMainTrees];
    }else{
        [[[UIAlertView alloc] initWithTitle:@"Can't connect to server" message:@"There was an error reaching the server. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        [self.refreshControl endRefreshing];
    }
}

-(void)handleOpenTreeNotification:(NSNotification*)notification{
    [self performSegueWithIdentifier:@"OpenTree" sender:notification.object];
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

-(void)refresh{
    if ([Config currentConfig].data) {
        [self loadMainTrees];
    }else{
        [[Config currentConfig] reloadData];
        [[Messages currentMessages] reloadData];
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
    if (result != nil && [result[@"status"] isEqualToString:@"OK"]) {
        
        self.trees = result[@"result"];
        [self.tableView reloadData];
    }else{
        [self showErrors:result[@"result"]];
    }
    _request = nil;

    
}

-(void)listRequestFailed:(ASIHTTPRequest*)sender{
    [self.refreshControl endRefreshing];
    [self showGeneralError];
    _request = nil;
}
//this should get generalized with the logic in Tree
-(void)showErrors:(NSArray*)errors{
    if (errors.count > 0) {
        NSString* message = [[Messages currentMessages] errorMessageForResult:errors];
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    }else{
        [self showGeneralError];
    }
}

-(void)showGeneralError{
    [[[UIAlertView alloc] initWithTitle:nil message:@"There was a problem contacting the server. Sorry!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
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
        if (section[@"detailText"]) {
            cell.detailTextLabel.text = section[@"detailText"];
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
        NSDictionary* query = nil;
        if ([sender isKindOfClass:[NSString class]]) {
            query = @{@"tree_name":sender};
        }else{
            query = @{@"tree_name":((UITableViewCell*)sender).textLabel.text};
        }
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

@end
