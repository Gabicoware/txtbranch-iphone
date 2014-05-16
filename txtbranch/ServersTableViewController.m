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
#import "ServerFormViewController.h"

enum {
    GeneralSection,
    ServersSection,
    TotalSection,
};

#define HasChangedServers @"com.gabicoware.txtbranch.HasChangedServers"

@interface ServersTableViewController ()

@end

@implementation ServersTableViewController{
    NSArray* _servers;
}

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

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return TotalSection;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case GeneralSection:
            return 1;
            break;
        case ServersSection:
            _servers = [[ServerList instance].servers sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSComparisonResult result = [obj1[@"name"] compare:obj2[@"name"] options:NSCaseInsensitiveSearch];
                if (result == NSOrderedSame) {
                    result = [obj1[@"address"] compare:obj2[@"address"] options:NSCaseInsensitiveSearch];
                }
                return result;
            }];
            return _servers.count;
        default:
            return 0;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == ServersSection) {
        return @"Servers";
    }
    return nil;
}


-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == ServersSection) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ServerCell"];
        NSDictionary* server = _servers[indexPath.row];
        cell.textLabel.text = server[@"name"];
        cell.detailTextLabel.text = server[@"address"];
        return cell;
    }else if (indexPath.section == GeneralSection) {
        return [tableView dequeueReusableCellWithIdentifier:@"AboutCell"];
    }
    NSAssert(NO, @"Should never reach this point");
    return nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Trees"] && sender != nil) {
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        
        NSDictionary* server = _servers[indexPath.row];
        
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
        [[AuthenticationManager instance] updateLoginState];
        
    }else if([segue.identifier isEqual:@"ServerForm"] && [sender isKindOfClass:[UITableViewCell class]]){
        NSIndexPath* indexPath = [self.tableView indexPathForCell:sender];
        NSDictionary* server = _servers[indexPath.row];
        UINavigationController* navController = (UINavigationController*)segue.destinationViewController;
        ServerFormViewController* controller = navController.viewControllers.firstObject;
        controller.server = server;
    }
}

@end
