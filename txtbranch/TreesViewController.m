//
//  TreesViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 3/5/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "TreesViewController.h"
#import "Messages.h"
#import "AFHTTPSessionManager+txtbranch.h"

@interface TreesViewController ()

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
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)refresh{
    
    id parameters = nil;
    if (self.query[@"username"]) {
        parameters = @{@"moderator":self.query[@"username"]};
    }else{
        parameters = @{@"list":@"main"};
    }
    
    __weak TreesViewController* weakSelf = self;
    
    [[AFHTTPSessionManager currentManager] GET:@"/api/v1/trees" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [weakSelf.refreshControl endRefreshing];
        if (responseObject != nil && [responseObject[@"status"] isEqualToString:@"OK"]) {
            
            weakSelf.trees = responseObject[@"result"];
            [weakSelf.tableView reloadData];
        }else{
            [weakSelf showErrors:responseObject[@"result"]];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [weakSelf.refreshControl endRefreshing];
        [weakSelf showGeneralError];
    }];
    
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
