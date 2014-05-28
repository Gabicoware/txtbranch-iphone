//
//  UserViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/27/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "UserViewController.h"
#import "AuthenticationManager.h"

@interface UserViewController()

@property (nonatomic, strong) NSArray* sections;

@end

@implementation UserViewController

@synthesize query=_query;

-(void)setQuery:(NSDictionary *)query{
    _query = query;
    
    self.sections = @[@{@"text":@"Activity",@"segue":@"Notifications",@"query":@{@"from_username":self.query[@"username"]}}];
    
    if ([self.query[@"username"] isEqualToString:[[AuthenticationManager instance] username]]) {
        self.sections = [@[@{@"text":@"Inbox",@"segue":@"Notifications",@"query":@{}}] arrayByAddingObjectsFromArray:self.sections];
    }
    [self.tableView reloadData];
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
