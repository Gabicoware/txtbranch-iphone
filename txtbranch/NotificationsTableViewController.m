//
//  NotificationsTableViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/8/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "NotificationsTableViewController.h"
#import "ASIHTTPRequest.h"
#import "NSURL+txtbranch.h"
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

@property (nonatomic, strong) ASIHTTPRequest* request;
@property (nonatomic, strong) NSArray* notifications;
@property (nonatomic, strong) NotificationFormatter* formatter;

@end

@implementation NotificationsTableViewController

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
        [self refresh];
    }
}

-(void)refresh{
    
    [_request cancel];
    
    NSString* path = nil;
    if (self.query ) {
        NSString* queryString = [self.query queryStringValue];
        path = [NSString stringWithFormat:@"/api/v1/notifications?%@",queryString] ;
    }else{
        path = @"/api/v1/notifications" ;
    }
    NSURL* URL = [NSURL tbURLWithPath:path];
    
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
        self.notifications = result[@"result"];
        [self.tableView reloadData];
    }
}

-(void)listRequestFailed:(ASIHTTPRequest*)sender{
    [self.refreshControl endRefreshing];
    NSLog(@"");
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.notifications.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationTableViewCell" forIndexPath:indexPath];
    cell.attributedLabel.text = [self.formatter stringWithNotification:self.notifications[indexPath.row]];
    
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
