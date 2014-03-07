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

@interface BranchViewController ()<BranchTableControllerDelegate>

@property (nonatomic,strong) ASIHTTPRequest* request;
@property (nonatomic,strong) BranchTableController* tableController;
@property (nonatomic,strong) IBOutlet UITableView* tableView;

@end

@implementation BranchViewController

-(void)awakeFromNib{
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardUpdate:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardUpdate:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

-(void)viewDidLoad{
    [super viewDidLoad];

    self.tableController = [[BranchTableController alloc] initWithTableView:self.tableView];
    self.tableController.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}

-(void)setTreeName:(NSString *)treeName{
    _treeName = treeName;
    [self loadTree:treeName];
    self.title = treeName;
}

-(void)loadTree:(NSString*)name{
    [_request cancel];
    
    NSURL* URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/trees?name=%@",name]];
    
	[self setRequest:[ASIHTTPRequest requestWithURL:URL]];
	[_request setTimeOutSeconds:20];
    
	[_request setDelegate:self];
	[_request setDidFailSelector:@selector(treeRequestFailed:)];
	[_request setDidFinishSelector:@selector(treeRequestFinished:)];
	
	[_request startAsynchronous];
}

-(void)treeRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
}

-(void)treeRequestFinished:(ASIHTTPRequest*)request{
    
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                              options:0
                                                error:&error];
    if ([result[@"status"] isEqualToString:@"OK"]) {
        self.tableController.tree = result[@"result"];
        
        [self loadBranches:@[result[@"result"][@"root_branch_key"]]];
    }
    
}

-(void)loadBranches:(NSArray*)branch_keys{
    NSMutableArray* params = [@[] mutableCopy];
    for (NSString* branch_key in branch_keys) {
        [params addObject:[NSString stringWithFormat:@"branch_key=%@",branch_key]];
    }
    NSURL* URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/branchs?%@",[params componentsJoinedByString:@"&"]]];
    [self loadBranchesURL:URL];
}

-(void)loadChildBranches:(NSString*)parentBranchKey{
    NSURL* URL = [NSURL tbURLWithPath:[NSString stringWithFormat:@"/api/v1/branchs?parent_branch_key=%@",parentBranchKey]];
    [self loadBranchesURL:URL];
}

-(void)loadBranchesURL:(NSURL*)URL{
    
	[self setRequest:[ASIHTTPRequest requestWithURL:URL]];
	[_request setTimeOutSeconds:20];
    
	[_request setDelegate:self];
	[_request setDidFailSelector:@selector(branchRequestFailed:)];
	[_request setDidFinishSelector:@selector(branchRequestFinished:)];
	
	[_request startAsynchronous];
    
}

-(void)branchRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
}

-(void)branchRequestFinished:(ASIHTTPRequest*)request{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    [self.tableController addBranches:result[@"result"]];
}

-(void)tableController:(BranchTableController*)controller didOpenBranchKey:(NSString*)branchKey{
    [self loadChildBranches:branchKey];
}

-(void)tableController:(BranchTableController*)controller addBranch:(NSDictionary*)branch{
    
    ASIFormDataRequest* request = [[ASIFormDataRequest alloc] initWithURL:[NSURL tbURLWithPath:@"/api/v1/branchs"]];
    
	[self setRequest:request];
    
    for (NSString* key in branch) {
        id value = branch[key];
        [request addPostValue:value forKey:key];
    }
    
	[_request setTimeOutSeconds:20];
    
	[_request setDelegate:self];
	[_request setDidFailSelector:@selector(addBranchRequestFailed:)];
	[_request setDidFinishSelector:@selector(addBranchRequestFinished:)];
	
	[_request startAsynchronous];
    
}

-(void)addBranchRequestFailed:(ASIHTTPRequest*)request{
    NSLog(@"%@",request.responseString);
}

-(void)addBranchRequestFinished:(ASIHTTPRequest*)request{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                options:0
                                                  error:&error];
    if (![result[@"status"] isEqualToString:@"ERROR"]) {
        [self.tableController addBranches:@[result[@"result"]]];
    }
}

-(AddBranchStatus)tableController:(BranchTableController*)controller statusForBranchKey:(NSString*)branchKey{
    return AddBranchStatusAllowed;
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
