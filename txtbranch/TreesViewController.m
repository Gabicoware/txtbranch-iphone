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
#import "SignInViewController.h"
#import "BranchViewController.h"

@interface TreesViewController ()

@property (nonatomic,strong) ASIHTTPRequest* request;

@property (nonatomic, retain) NSArray* trees;

@end

@implementation TreesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"txtbranch";

    [self loadMainTrees];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.trees.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TreeTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary* tree = [self.trees objectAtIndex:indexPath.row];
    
    cell.textLabel.text = tree[@"name"];
    cell.detailTextLabel.text = tree[@"moderator_name"];
    
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    ((BranchViewController*)segue.destinationViewController).treeName = ((UITableViewCell*)sender).textLabel.text;
}

@end
