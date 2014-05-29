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
#import "NSURL+txtbranch.h"
#import "Messages.h"

@interface TreesViewController ()

@property (nonatomic,strong) ASIHTTPRequest* request;

@property (nonatomic, strong) NSArray* trees;

@end

@implementation TreesViewController

@synthesize query=_query;

-(void)setQuery:(NSDictionary *)query{
    _query = query;
    [self refresh];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    
    [self.refreshControl addTarget:self action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.refreshControl beginRefreshing];
    
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.request cancel];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)refresh{
    [_request cancel];
    
    NSURL* URL = nil;
    if (self.query[@"username"]) {
        URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/trees?moderator=%@",self.query[@"username"]]];
    }else{
        URL = [NSURL tbURLWithPath:@"/api/v1/trees?list=main"];
    }
    
    
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

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.trees.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TreeTableViewCell" forIndexPath:indexPath];
    
    NSDictionary* tree = [self.trees objectAtIndex:indexPath.row];
    
    cell.textLabel.text = tree[@"name"];
    if ([tree[@"content_moderator_only"] isEqual:@(1)]) {
        cell.detailTextLabel.text = @"Text Adventure";
    }else{
        cell.detailTextLabel.text = @"Collaborative Story";
    }
    
    return cell;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"OpenTree"]) {
        id<Queryable> controller = (id<Queryable>)segue.destinationViewController;
        NSDictionary* query = nil;
        if ([sender isKindOfClass:[NSString class]]) {
            query = @{@"tree_name":sender};
        }else{
            query = @{@"tree_name":((UITableViewCell*)sender).textLabel.text};
        }
        controller.query = query;
    }
    
}

@end
