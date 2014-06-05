//
//  NotificationsTableViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/8/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "NotificationsTableViewController.h"
#import "QueryableList.h"
#import "NSDictionary+QueryString.h"
#import "TTTAttributedLabel.h"
#import "NotificationFormatter.h"

@class NotificationTableViewCell;


@interface NotificationTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet TTTAttributedLabel* attributedLabel;

@end

@implementation NotificationTableViewCell

@end

@interface NotificationsTableViewController ()<TTTAttributedLabelDelegate>

@property (nonatomic, strong) NotificationFormatter* formatter;

@end

@implementation NotificationsTableViewController

-(void)dealloc{
    [self.list removeObserver:self forKeyPath:@"items"];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.formatter = [[NotificationFormatter alloc] init];
}

-(void)setQuery:(NSDictionary *)query{
    if (![query isEqualToDictionary:_query]) {
        if (_query[@"from_username"]) {
            self.title = _query[@"from_username"];
        }
        _query = [query copy];
        
        [self.list removeObserver:self forKeyPath:@"items"];
        self.list = [[QueryableList alloc] init];
        self.list.query = _query;
        self.list.basePath = @"/api/v1/notifications";
        
        [self.list addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:NULL];
        
        [self.list refresh];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.list.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationTableViewCell" forIndexPath:indexPath];
    cell.attributedLabel.text = [self.formatter stringWithNotification:self.list.items[indexPath.row]];
    
    // Configure the cell...
    
    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url{
    NSDictionary* notification = self.formatter.URLToNotifications[url];
    //if we have the notification
    if(notification){
        NSDictionary* params = [NSDictionary dictionaryWithQueryString:url.query];
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        if ([params[@"itemType"] isEqualToString:@"username"]) {
            NSDictionary* query = @{@"username":notification[@"from_username"]};
            
            UIViewController<Queryable>* controller = [storyboard instantiateViewControllerWithIdentifier:@"UserViewController"];
            controller.title = notification[@"from_username"];
            controller.query = query;
            [self.navigationController pushViewController:controller animated:YES];
        }else if ([params[@"itemType"] isEqualToString:@"tree_name"]) {
            UIViewController<Queryable>* controller = [storyboard instantiateViewControllerWithIdentifier:@"BranchViewController"];
            NSDictionary* query = @{@"tree_name":notification[@"tree_name"]};
            controller.query = query;
            [self.navigationController pushViewController:controller animated:YES];
        }else if ([params[@"itemType"] isEqualToString:@"link"]) {
            UIViewController<Queryable>* controller = [storyboard instantiateViewControllerWithIdentifier:@"BranchViewController"];
            NSDictionary* query = @{@"tree_name":notification[@"tree_name"],@"branch_key":notification[@"branch_key"]};
            controller.query = query;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}
@end
