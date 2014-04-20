//
//  ViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "BranchTableController.h"
#import "NSURL+txtbranch.h"

@interface BranchViewController ()

@property (nonatomic,strong) ASIHTTPRequest* request;
@property (nonatomic,strong) BranchTableController* tableController;
@property (nonatomic,strong) IBOutlet UITableView* tableView;
@property (nonatomic,strong) Tree* tree;

@end

@implementation BranchViewController{
    NSString* _branchKey;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardUpdate:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardUpdate:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

-(void)viewDidLoad{
    [super viewDidLoad];

    self.tableController = [[BranchTableController alloc] initWithTableView:self.tableView];
    
    self.tableController.tree = self.tree;
    if (self.query[@"branch"]) {
        self.tableController.currentBranchKey = self.query[@"branch"];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

-(void)setQuery:(NSDictionary *)query{
    _query = query;
    
    NSAssert(query[@"tree_name"] != nil, @"tree_name key should be not nil in query");
    
    NSString* treeName = query[@"tree_name"];
    
    self.tree = [[Tree alloc] initWithName:treeName];
    
    self.title = treeName;
    
    if (query[@"branch"]) {
        self.tableController.currentBranchKey = query[@"branch"];
        [self.tree loadBranches:@[query[@"branch"]]];
    }
    self.tableController.tree = self.tree;
}

-(void)handleKeyboardUpdate:(NSNotification*)notification{
    
    if(self.view.window == nil){
        return;
    }
    
    NSValue* value = (NSValue*)notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect rect = [value CGRectValue];
    CGRect keyboardRect = [self.view convertRect:rect fromView:self.view.window];
    CGRect viewRect = self.view.bounds;
    
    CGRect tableViewRect = self.tableView.frame;
    
    if (CGRectIntersectsRect(viewRect, keyboardRect)) {
        CGRect intersection = CGRectIntersection(viewRect, keyboardRect);
        tableViewRect.size.height = intersection.origin.y - tableViewRect.origin.y;
    }else{
        tableViewRect.size.height = viewRect.size.height - tableViewRect.origin.y;
    }
    
    NSNumber* duration = (NSNumber*)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    
    CGRect formRect = [self.tableController addBranchFormRect];
    
    CGPoint center = CGPointMake( CGRectGetMidX( tableViewRect ) , CGRectGetMidY( tableViewRect ) );
    
    CGRect tableViewBounds = tableViewRect;
    
    tableViewBounds.origin.x = 0.0;
    
    if (CGRectEqualToRect(formRect, CGRectNull)) {
        if (tableViewBounds.size.height < self.tableView.contentSize.height) {
            tableViewBounds.origin.y = self.tableView.contentOffset.y;
        }else{
            tableViewBounds.origin.y = 0;
        }
        
    }else{
        tableViewBounds.origin.y = CGRectGetMaxY(formRect) - tableViewBounds.size.height;
    }
    
    [UIView animateWithDuration:[duration doubleValue] animations:^{
        self.tableView.center = center;
        self.tableView.bounds = tableViewBounds;
    }];
    
    
}


@end
