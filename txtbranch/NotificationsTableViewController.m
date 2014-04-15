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
#import "BranchViewController.h"
#import "TTTAttributedLabel.h"

@class NotificationTableViewCell;


@interface NotificationTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet TTTAttributedLabel* attributedLabel;

@end

@implementation NotificationTableViewCell

@end

@interface NotificationsTableViewController ()<TTTAttributedLabelDelegate>

@property (nonatomic, strong) ASIHTTPRequest* request;
@property (nonatomic, strong) NSArray* notifications;
@property (nonatomic, strong) NSMutableDictionary* URLToNotifications;

@end

@implementation NotificationsTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.URLToNotifications = [@{} mutableCopy];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setQuery:(NSDictionary *)query{
    if (![query isEqualToDictionary:_query]) {
        _query = query;
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
    cell.attributedLabel.text = [self stringWithNotification:self.notifications[indexPath.row]];
    
    // Configure the cell...
    
    return cell;
}

-(NSMutableAttributedString*)stringWithNotification:(NSDictionary*)notification{
    
    NSDictionary* normalAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-LightItalic" size:15]};
    
    NSArray* stringSections = [self stringSectionsWithNotification:notification];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:@"" attributes:normalAttributes];
    for (NSDictionary* stringSection in stringSections) {
        
        NSDictionary* attributes = nil;
        
        if ([stringSection[@"type"] isEqualToString:@"item"]) {
            NSDictionary* params = @{@"itemType": stringSection[@"itemType"],
                                     @"notification": notification[@"key"]};
            NSString* queryString = [params queryStringValue];
            NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"txtbranch://?%@",queryString]];
            self.URLToNotifications[URL] = notification;
            attributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Italic" size:15],
                           NSLinkAttributeName:URL,
                           NSForegroundColorAttributeName:[UIColor darkGrayColor]};
        }else{
            attributes = normalAttributes;
        }
        
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:stringSection[@"string"] attributes:attributes]];
    }
    
    return [string copy];
    
}

-(NSArray*)stringSectionsWithNotification:(NSDictionary*)notification{
    
    NSString* username = notification[@"from_username"];
    NSString* message = @"";
    
    if ([notification[@"notification_type"] isEqualToString:@"new_branch"]) {
        message = @"added a branch";
    }else if ([notification[@"notification_type"] isEqualToString:@"edit_branch"]) {
        message = @"edited a branch";
    }
    NSString* treename = notification[@"tree_name"];
    NSString* link = notification[@"branch_link"];
    
    NSMutableArray* array = [NSMutableArray array];
    
    [array addObject:@{@"string":username,@"type":@"item",@"itemType":@"username"}];
    [array addObject:@{@"string":@" ",@"type":@"text"}];
    [array addObject:@{@"string":message,@"type":@"text"}];
    [array addObject:@{@"string":@" \"",@"type":@"text"}];
    [array addObject:@{@"string":link,@"type":@"item",@"itemType":@"link"}];
    [array addObject:@{@"string":@"\" in ",@"type":@"text"}];
    [array addObject:@{@"string":treename,@"type":@"item",@"itemType":@"tree_name"}];
    
    return [array copy];
    
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url{
    NSDictionary* notification = self.URLToNotifications[url];
    //if we have the notification
    if(notification){
        NSDictionary* params = [NSDictionary dictionaryWithQueryString:url.query];
        
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        if ([params[@"itemType"] isEqualToString:@"username"]) {
            NSDictionary* query = @{@"from_username":notification[@"from_username"]};
            
            if (![query isEqualToDictionary:self.query]) {
                NotificationsTableViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"NotificationsTableViewController"];
                controller.title = notification[@"from_username"];
                controller.query = query;
                [self.navigationController pushViewController:controller animated:YES];
            }
        }else if ([params[@"itemType"] isEqualToString:@"tree_name"]) {
            BranchViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BranchViewController"];
            NSDictionary* query = @{@"tree_name":notification[@"tree_name"]};
            controller.query = query;
            [self.navigationController pushViewController:controller animated:YES];
        }else if ([params[@"itemType"] isEqualToString:@"link"]) {
            BranchViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BranchViewController"];
            NSDictionary* query = @{@"tree_name":notification[@"tree_name"],@"branch":notification[@"branch"]};
            controller.query = query;
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

@end
