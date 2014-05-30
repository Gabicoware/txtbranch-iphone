//
//  ViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchViewController.h"
#import "Tree.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSURL+txtbranch.h"
#import "BranchTableViewCell.h"
#import "TBTextView.h"
#import "AuthenticationManager.h"
#import "NSDictionary+QueryString.h"
#import "UIAlertView+Block.h"

#define IsLinkRow(indexPath) (indexPath.row%2 == 0)
#define IsOrRow(indexPath) (indexPath.row%2 == 1)
#define IsContentRow(indexPath) (indexPath.row%2 == 1)
#define LinkRow(indexPath) (indexPath.row/2)
//AboutHiddenTableViewCell


NS_ENUM(NSInteger, BranchTableSection){
    BranchTableSectionAbout,
    BranchTableSectionLoadParent,
    BranchTableSectionBranches,
    BranchTableSectionLinks,
    BranchTableSectionAddBranch,
    BranchTableSectionTotal
};

#define IsNotNull(object) (![[NSNull null] isEqual:object] && object != nil)

@interface BranchViewController ()<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>

@property (nonatomic, assign) BOOL needsParentBranch;
@property (nonatomic,strong) ASIHTTPRequest* request;
@property (nonatomic,strong) IBOutlet UITableView* tableView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem* editItem;
@property (nonatomic,strong) Tree* tree;

@property (nonatomic, strong) NSString* currentBranchKey;

@end

@implementation BranchViewController{
    NSString* _branchKey;
    NSMutableArray* _branchKeys;
    NSArray* _childBranchKeys;
    BOOL _isAboutHidden;
    NSMutableDictionary* _cells;
    NSString* _currentBranchKey;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)awakeFromNib{
    [super awakeFromNib];
    [self setupNotifications];
    _cells = [NSMutableDictionary dictionary];
}

-(void)setupNotifications{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTreeDidUpdateBranchesNotification:) name:TreeDidUpdateBranchesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTreeDidUpdateTreeNotification:) name:TreeDidUpdateTreeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTreeDidAddBranchesNotification:) name:TreeDidAddBranchesNotification object:nil];
}

-(void)viewDidLoad{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self updateEditButton];
}

-(void)updateEditButton{
    if ([AuthenticationManager instance].isLoggedIn && [self.tree isModerator] ) {
        self.navigationItem.rightBarButtonItem = self.editItem;
    }else{
        self.navigationItem.rightBarButtonItem = nil;
    }
}

-(void)setQuery:(NSDictionary *)query{
    _query = [query copy];
    
    NSAssert(query[@"tree_name"] != nil, @"tree_name key should be not nil in query");
    
    NSString* treeName = query[@"tree_name"];
    
    self.tree = [[Tree alloc] initWithName:treeName];
    
    self.title = treeName;
    
    if (query[@"branch_key"]) {
        self.currentBranchKey = query[@"branch_key"];
        [self.tree loadBranches:@[query[@"branch_key"]]];
    }
}

-(void)handleTreeDidUpdateBranchesNotification:(NSNotification*)notification
{
    if ([notification.object isEqual:self.tree]) {
        NSArray* branches = notification.userInfo[TreeNotificationBranchesUserInfoKey];
        [self addBranches:branches];
    }
}

-(void)addBranches:(NSArray *)objects{
    
    NSMutableArray* keys = [NSMutableArray array];
    
    NSMutableArray* reloadedArray = [NSMutableArray array];
    
    BOOL isLink = YES;
    
    for (NSDictionary* branch in objects) {
        NSInteger row = [_branchKeys indexOfObject:branch[@"key"]];
        if (row != NSNotFound) {
            [reloadedArray addObject:[NSIndexPath indexPathForRow:(row*2) inSection:BranchTableSectionBranches]];
            [reloadedArray addObject:[NSIndexPath indexPathForRow:(row*2+1) inSection:BranchTableSectionBranches]];
        }
        [keys addObject:branch[@"key"]];
        if (![branch[@"parent_branch_key"] isEqual:_currentBranchKey]) {
            isLink = NO;
        }
    }
    NSString* parentBranch = self.tree.branches[_branchKeys.firstObject][@"parent_branch_key"];
    if (!IsNotNull(parentBranch)) {
        self.needsParentBranch = NO;
    }else{
        self.needsParentBranch = ![_branchKeys containsObject:parentBranch];
        if (self.needsParentBranch && self.tree.branches[parentBranch] == nil) {
            [self.tree loadBranches:@[parentBranch]];
        }else if ([keys containsObject:parentBranch]) {
            [reloadedArray addObject:[NSIndexPath indexPathForRow:0 inSection:BranchTableSectionLoadParent]];
        }
        
    }
    
    if(isLink){
        _childBranchKeys = keys;
    }
    [self.tableView beginUpdates];
    
    [self.tableView reloadRowsAtIndexPaths:reloadedArray
                          withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:BranchTableSectionLinks]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
    if (isLink && 1 < _branchKeys.count) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(2*([_branchKeys count]-1)) inSection:BranchTableSectionBranches];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
}

-(void)setNeedsParentBranch:(BOOL)needsParentBranch{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:BranchTableSectionLoadParent];
    if (needsParentBranch != _needsParentBranch) {
        _needsParentBranch = needsParentBranch;
        if (needsParentBranch) {
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }else{
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }else if(needsParentBranch){
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

-(void)handleTreeDidUpdateTreeNotification:(NSNotification*)notification{
    if ([self.tree isEqual:notification.object]) {
        if (self.currentBranchKey == nil) {
            _currentBranchKey = self.tree.data[@"root_branch_key"];
        }
        _branchKeys = [@[_currentBranchKey] mutableCopy];
        [self.tableView reloadData];
        [self.tree loadChildBranches:_currentBranchKey];
        [self updateEditButton];
    }
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return BranchTableSectionTotal;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger result = 0;
    switch (section) {
        case BranchTableSectionAbout:
            result = 1;
            break;
        case BranchTableSectionLoadParent:
            result = self.needsParentBranch ? 1 : 0;
            break;
        case BranchTableSectionBranches:
            result = [_branchKeys count]*2 + 1;
            break;
        case BranchTableSectionLinks:
            result = [_childBranchKeys count] * 2;
            break;
        case BranchTableSectionAddBranch:
            result = 1;
            break;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString* reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    [self customizeCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

-(void)customizeCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    switch ([indexPath section]) {
        case BranchTableSectionAbout:{
            AboutTableViewCell* headerCell = (id)cell;
            headerCell.aboutLabel.text = self.tree.data[@"conventions"];
            headerCell.isAboutHidden = _isAboutHidden;
            break;
        }
        case BranchTableSectionLoadParent:{
            
            NSString* parentBranch = self.tree.branches[_branchKeys.firstObject][@"parent_branch_key"];
            NSDictionary* branchData = self.tree.branches[parentBranch];
            if (branchData == nil) {
                cell.textLabel.text = [NSString stringWithFormat:@"↑"];
            }else{
                cell.textLabel.text = [NSString stringWithFormat:@"↑ %@",branchData[@"link"]];
            }
            break;
        }
        case BranchTableSectionBranches:{
            
            if (indexPath.row < _branchKeys.count*2) {
                NSString* branchKey = _branchKeys[LinkRow(indexPath)];
                id branch = self.tree.branches[ branchKey ];
                if (IsLinkRow(indexPath)) {
                    LinkTableViewCell* branchCell = (id)cell;
                    branchCell.linkLabel.text = branch[@"link"];
                    branchCell.isLink = NO;
                }else{
                    ContentTableViewCell* branchCell = (id)cell;
                    branchCell.contentLabel.text = branch[@"content"];
                }
            }
            break;
        }
        case BranchTableSectionLinks:{
            
            if (IsLinkRow(indexPath) && LinkRow(indexPath) < _childBranchKeys.count) {
                id branch = self.tree.branches[ _childBranchKeys[LinkRow(indexPath)]];
                LinkTableViewCell* linkCell = (id)cell;
                linkCell.linkLabel.text = branch[@"link"];
                linkCell.isLink = YES;
            }
            
            break;
        }
    }
}

#define AuthornameString(branch) ([NSString stringWithFormat:@"by %@",branch[@"authorname"]])

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    NSString* key = _branchKeys[LinkRow(indexPath)];
    id branch = self.tree.branches[ key ];
    
    NSString* deleteButtonTitle = nil;
    
    if([self.tree canDeleteBranch:key]){
        deleteButtonTitle = @"Delete";
    }
    
    NSString* editButtonTitle = nil;
    
    if([self.tree canEditBranch:key]){
        editButtonTitle = @"Edit";
    }
    
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:deleteButtonTitle otherButtonTitles:AuthornameString(branch), editButtonTitle, nil];
    actionSheet.tag = LinkRow(indexPath);
    [actionSheet showInView:self.view];
    
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if (actionSheet.tag < _branchKeys.count) {
        NSString* key = _branchKeys[actionSheet.tag];
        
        id branch = self.tree.branches[ key ];
        
        if (branch != nil) {
            NSString* title = [actionSheet buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Delete"]) {
                [[[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Are you sure you want to delete this branch?" cancelButtonTitle:@"Keep it" otherButtonTitles:@[@"Delete it"] block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex == 1) {
                        NSDictionary * branch = self.tree.branches[_currentBranchKey];
                        
                        [_branchKeys removeLastObject];
                        _currentBranchKey = [_branchKeys lastObject];
                        [self.tableView reloadData];
                        [self.tree deleteBranch:branch];
                    }
                }] show];
                
            }else if ([title isEqualToString:@"Edit"]) {
                [self performSegueWithIdentifier:@"BranchForm" sender:@{@"branchKey":branch[@"key"],@"tree":self.tree}];
            }else if ([title isEqualToString:AuthornameString(branch)]) {
                NSString* authorname = branch[@"authorname"];
                [self performSegueWithIdentifier:@"UserView" sender:authorname];
            }
        }
        
    }
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* reuseIdentifier = [self reuseIdentifierForRowAtIndexPath:indexPath];
    UITableViewCell* cell = _cells[reuseIdentifier];
    if (cell == nil) {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        _cells[reuseIdentifier] = cell;
    }
    [self customizeCell:cell forRowAtIndexPath:indexPath];
    if ( cell.frame.size.width != tableView.bounds.size.width ) {
        CGRect frame = cell.frame;
        frame.size.width = tableView.bounds.size.width;
        cell.frame = frame;
        [cell layoutSubviews];
    }
    return [cell sizeThatFits:tableView.bounds.size].height;
}

-(NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch ([indexPath section]) {
        case BranchTableSectionAbout:
            return @"AboutTableViewCell";
            break;
        case BranchTableSectionLoadParent:
            return @"LoadParentTableViewCell";
            break;
        case BranchTableSectionBranches:
            if (indexPath.row < _branchKeys.count*2) {
                if (IsLinkRow(indexPath)) {
                    return @"LinkTableViewCell";
                }else{
                    return @"ContentTableViewCell";
                }
            }else{
                return @"CurrentBranchMedatataCell";
            }
            break;
        case BranchTableSectionLinks:
            if (IsOrRow(indexPath)) {
                return @"OrTableViewCell";
            }else{
                return @"LinkTableViewCell";
            }
            break;
        case BranchTableSectionAddBranch:
            return @"AddBranchTableViewCell";
            break;
    }
    return nil;
}

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ( indexPath.section == BranchTableSectionBranches && _branchKeys.count*2 <= indexPath.row ) {
        return nil;
    }else if(indexPath.section == BranchTableSectionBranches && IsContentRow(indexPath)){
        return nil;
    }else if(indexPath.section == BranchTableSectionLinks && IsOrRow(indexPath)){
        return nil;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == BranchTableSectionLoadParent) {
        
        NSString* parentBranch = self.tree.branches[_branchKeys.firstObject][@"parent_branch_key"];
        
        if (IsNotNull(parentBranch)) {
            [self.tree loadChildBranches:parentBranch];
            [_branchKeys insertObject:parentBranch atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:BranchTableSectionBranches],[NSIndexPath indexPathForRow:1 inSection:BranchTableSectionBranches]] withRowAnimation:UITableViewRowAnimationFade];
            
            NSString* nextParentBranch = self.tree.branches[parentBranch][@"parent_branch_key"];
            
            self.needsParentBranch = IsNotNull(nextParentBranch);
            if (self.needsParentBranch) {
                [self.tree loadBranches:@[parentBranch]];
            }
            
        }
        
    }else if (indexPath.section == BranchTableSectionAbout) {
        _isAboutHidden = !_isAboutHidden;
        //update the current cell
        AboutTableViewCell* cell = (id)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:BranchTableSectionAbout]];
        cell.isAboutHidden = _isAboutHidden;
        //update the heights
        [tableView beginUpdates];
        [tableView endUpdates];
    }else if (indexPath.section == BranchTableSectionLinks) {
        if (IsOrRow( indexPath )) {
            return;
        }
        _currentBranchKey = _childBranchKeys[LinkRow(indexPath)];
        NSIndexPath* newLinkIndexPath = [NSIndexPath indexPathForRow:([_branchKeys count]*2) inSection:BranchTableSectionBranches];
        NSIndexPath* newContentIndexPath = [NSIndexPath indexPathForRow:([_branchKeys count]*2 + 1) inSection:BranchTableSectionBranches];
        [_branchKeys addObject:_currentBranchKey];
        NSMutableArray* links = [NSMutableArray array];
        for (int row = 0; row < _childBranchKeys.count*2; row++) {
            if (row != indexPath.row) {
                [links addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionLinks]];
            }
        }
        _childBranchKeys = nil;
        
        LinkTableViewCell* cell = (LinkTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.isLink = NO;
        [tableView beginUpdates];
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newLinkIndexPath];
        [self.tableView insertRowsAtIndexPaths:@[newContentIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView deleteRowsAtIndexPaths:links withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        [self.tree loadChildBranches:_currentBranchKey];
        //[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionBranches) {
        
        NSUInteger branchIndex = LinkRow(indexPath);
        
        if ([_currentBranchKey isEqualToString: _branchKeys[branchIndex]]) {
            [self.tree loadChildBranches:_currentBranchKey];
            return;
        }
        _currentBranchKey = _branchKeys[branchIndex];
        NSRange range = NSMakeRange(branchIndex+1, _branchKeys.count - branchIndex-1);
        NSMutableArray* indexes = [@[] mutableCopy];
        for (NSInteger index = range.location; index < range.length + range.location; index++) {
            [indexes addObject:[NSIndexPath indexPathForRow:index*2 inSection:BranchTableSectionBranches]];
            [indexes addObject:[NSIndexPath indexPathForRow:index*2+1 inSection:BranchTableSectionBranches]];
        }
        
        //TODO: fix this
        [_branchKeys removeObjectsInRange:range];
        [tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
        _childBranchKeys = nil;
        [self.tree loadChildBranches:_currentBranchKey];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionAddBranch) {
        
        AddBranchStatus status = [self.tree addBranchStatus:_currentBranchKey];
        
        switch (status) {
            case AddBranchStatusAllowed:{
                [self performSegueWithIdentifier:@"BranchForm" sender:@{@"parentBranchKey":_currentBranchKey,@"tree":self.tree}];
                break;
            }
            case AddBranchStatusNeedsLogin:{
                [self showNeedsLogin];
                break;
            }
            case AddBranchStatusHasBranches:{
                [self showHasBranchesAlert];
                break;
            }
                
                
        }
    }
}

-(void)showNeedsLogin{
    [[[UIAlertView alloc] initWithTitle:nil message:@"You must log in to add a branch." cancelButtonTitle:@"Cancel" otherButtonTitles:@[@"Login"] block:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self performSegueWithIdentifier:@"Login" sender:nil];
        }
    }] show];
}

-(void)showHasBranchesAlert{
    
    NSString* message = [NSString stringWithFormat: @"You have already created the max number of children for this branch (%lu). Try finding another branch to add children to.",(unsigned long)self.tree.branchMax];
    
    [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}


-(void)handleTreeDidAddBranchesNotification:(NSNotification*)notification{
    NSArray * branches = notification.userInfo[TreeNotificationBranchesUserInfoKey];
    
    _currentBranchKey = branches.firstObject[@"key"];
    [_branchKeys addObject:_currentBranchKey];
    _childBranchKeys = nil;
    [self.tableView reloadData];
    
    [self.tree loadChildBranches:_currentBranchKey];
    
}

#pragma UIKeyboard


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"UserView"] && [sender isKindOfClass:[NSString class]]) {
        UIViewController<Queryable>* controller = segue.destinationViewController;
        controller.query = @{@"username":sender};
        controller.title = sender;
    }
    if ([segue.identifier isEqualToString:@"TreeForm"]) {
        UINavigationController* navController = segue.destinationViewController;
        id<Queryable> controller = [[navController viewControllers] firstObject];
        controller.query = self.query;
    }
    if ([segue.identifier isEqualToString:@"BranchForm"] && [sender isKindOfClass:[NSDictionary class]]) {
        UINavigationController* navController = segue.destinationViewController;
        id<Queryable> controller = [[navController viewControllers] firstObject];
        controller.query = sender;
    }
    
}


@end
