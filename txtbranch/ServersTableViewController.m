//
//  SettingsTableViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/24/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "ServersTableViewController.h"
#import "AuthenticationManager.h"
#import "ServerList.h"

#define HasChangedServers @"com.gabicoware.txtbranch.HasChangedServers"

@interface ServersTableViewController ()

@end

@implementation ServersTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    [self performSegueWithIdentifier:@"Trees" sender:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [ServerList instance].servers.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ServerCell"];
    NSDictionary* server = [ServerList instance].servers[indexPath.row];
    cell.textLabel.text = server[@"name"];
    cell.detailTextLabel.text = server[@"address"];
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Trees"] && sender != nil) {
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        
        NSDictionary* server = [ServerList instance].servers[indexPath.row];
        
        BOOL hasChanged = [[NSUserDefaults standardUserDefaults] boolForKey:HasChangedServers];
        
        if (!hasChanged && ![server isEqual:[[ServerList instance] activeServer]]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HasChangedServers];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[[UIAlertView alloc] initWithTitle:@"Changing Servers"
                                        message:@"Sessions do not transfer between servers. You will have to sign in on every new server you want to join."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil]
             show];
        }
        
        [[ServerList instance] setActiveServer:server];
        
    }
}

@end
