//
//  ViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchViewController.h"
#import "Tree.h"
#import "BranchTableViewCell.h"
#import "TBTextView.h"
#import "AuthenticationManager.h"
#import "NSDictionary+QueryString.h"
#import "UIAlertView+Block.h"
#import "txtbranch-Swift.h"
#import "NSFoundation+Ext.h"

#define IsLinkRow(indexPath) (indexPath.row%2 == 0)
#define IsOrRow(indexPath) (indexPath.row%2 == 1)
#define IsContentRow(indexPath) (indexPath.row%2 == 1)
#define LinkRow(indexPath) (indexPath.row/2)
//AboutHiddenTableViewCell

@interface NSArray(Constructors)
//use the javascript terminology, because that's what I'm familiar with

-(NSArray*)arrayByShift;

-(NSArray*)arrayByUnshift:(id)object;

-(NSArray*)arrayByPop;

-(NSArray*)arrayByPush:(id)object;

//a subarray up to and including the element
-(NSArray*)subarrayToElement:(id)object;

@end


NS_ENUM(NSInteger, BranchTableSection){
    BranchTableSectionLoadParent,
    BranchTableSectionBranches,
    BranchTableSectionLinks,
    BranchTableSectionAddBranch,
    BranchTableSectionTotal
};

#define IsNotNull(object) (![[NSNull null] isEqual:object] && object != nil)
#define NotNull(object) (![[NSNull null] isEqual:object] ? object : nil)

@interface BranchViewController ()<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>

@property (nonatomic,strong) IBOutlet UITableView* tableView;
@property (nonatomic,strong) Tree* tree;
//the model representing the state of the table
@property (nonatomic,strong) BranchViewModel* branchViewModel;

@end

@implementation BranchViewController{
    NSMutableDictionary* _cells;
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}


-(void)setQuery:(NSDictionary *)query{
    _query = [query copy];
    
    BranchViewModel* model = [[BranchViewModel alloc] init];
    
    NSAssert(query[@"tree_name"] != nil, @"tree_name key should be not nil in query");
    
    NSString* treeName = query[@"tree_name"];
    
    self.tree = [[Tree alloc] initWithName:treeName];
    
    self.title = treeName;
    
    if (query[@"branch_key"]) {
        model.branchKeys = @[query[@"branch_key"]];
        
        [self.tree loadBranches:@[query[@"branch_key"]]];
    }
    [self updateBranchViewModel:model];
}

-(void)handleTreeDidUpdateBranchesNotification:(NSNotification*)notification
{
    if ([notification.object isEqual:self.tree]) {
        NSArray* branches = notification.userInfo[TreeNotificationBranchesUserInfoKey];
        [self addBranches:branches];
    }
}

-(void)updateBranchViewModel:(BranchViewModel*)model{
    
    //we can make this update every time
    model.branches = [self.tree branchesForKeys:model.allKeys];
    
    if (self.branchViewModel == nil && model != nil) {
        self.branchViewModel = model;
        [self.tableView reloadData];
    }else if (![self.branchViewModel isEqual:model]) {
        BranchViewModel* existing = self.branchViewModel;
        self.branchViewModel = model;
        
        NSDictionary* changes = [self changesWithExisting:existing proposed:model];
        
        [[self tableView] beginUpdates];
        
        [changes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:@"delete"] && [obj count] > 0) {
                [self.tableView deleteRowsAtIndexPaths:obj withRowAnimation:UITableViewRowAnimationTop];
            }else if ([key isEqualToString:@"insert"] && [obj count] > 0) {
                [self.tableView insertRowsAtIndexPaths:obj withRowAnimation:UITableViewRowAnimationTop];
            }else if ([key isEqualToString:@"reload"] && [obj count] > 0) {
                [self.tableView reloadRowsAtIndexPaths:obj withRowAnimation:UITableViewRowAnimationFade];
            }else if ([key isEqualToString:@"reloadSection"] && [obj count] > 0) {
                [self.tableView reloadSections:obj withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
        
        [[self tableView] endUpdates];
        
    }
    
}

-(NSDictionary*)changesWithExisting:(BranchViewModel*)existing proposed:(BranchViewModel*)proposed{
    
    NSMutableArray* deleteIndexPaths = [NSMutableArray array];
    NSMutableArray* insertIndexPaths = [NSMutableArray array];
    NSMutableArray* reloadIndexPaths = [NSMutableArray array];
    NSMutableIndexSet* reloadSectionIndexSet = [NSMutableIndexSet indexSet];
    
    {
        //branches
        NSMutableSet* keySet = [NSMutableSet setWithArray:proposed.branchKeys];
        
        [keySet intersectSet:[NSSet setWithArray:existing.branchKeys]];
        
        [existing.branchKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![keySet containsObject:obj]) {
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(idx*2) inSection:BranchTableSectionBranches]];
                [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:(idx*2+1) inSection:BranchTableSectionBranches]];
            }
        }];
        
        [keySet enumerateObjectsUsingBlock:^(NSString* key, BOOL *stop) {
            if (existing.branches[key] != proposed.branches[key] && ![existing.branches[key] isEqual:proposed.branches[key]] ) {
                NSInteger row = [existing.branchKeys indexOfObject:key];
                [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:(row*2) inSection:BranchTableSectionBranches]];
                [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:(row*2+1) inSection:BranchTableSectionBranches]];
            }
        }];
        
        [proposed.branchKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![keySet containsObject:obj]) {
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:(idx*2) inSection:BranchTableSectionBranches]];
                [insertIndexPaths addObject:[NSIndexPath indexPathForRow:(idx*2+1) inSection:BranchTableSectionBranches]];
            }
        }];
    }
    {
        //links
        NSMutableSet* keySet = [NSMutableSet setWithArray:proposed.childBranchKeys];
        
        [keySet intersectSet:[NSSet setWithArray:existing.childBranchKeys]];
        
        if ([keySet count] > 0) {
            
            [existing.childBranchKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger row, BOOL *stop) {
                if (![keySet containsObject:obj]) {
                    [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionLinks]];
                }
            }];
            
            [keySet enumerateObjectsUsingBlock:^(NSString* key, BOOL *stop) {
                if (existing.branches[key] != proposed.branches[key] && ![existing.branches[key] isEqual:proposed.branches[key]] ) {
                    NSInteger row = [existing.childBranchKeys indexOfObject:key];
                    [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionLinks]];
                }
            }];
            
            [proposed.childBranchKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger row, BOOL *stop) {
                if (![keySet containsObject:obj]) {
                    [insertIndexPaths addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionLinks]];
                }
            }];
        }else if(existing.childBranchKeys.count > 0 || proposed.childBranchKeys.count > 0){
            [reloadSectionIndexSet addIndex:BranchTableSectionLinks];
        }
        
    }
    
    {
        //load parent
        NSIndexPath* parentBranchIndexPath = [NSIndexPath indexPathForRow:0 inSection:BranchTableSectionLoadParent];
        
        if (proposed.hasParentBranchKey != existing.hasParentBranchKey) {
            if (proposed.hasParentBranchKey) {
                [insertIndexPaths addObject:parentBranchIndexPath];
            }else{
                [deleteIndexPaths addObject:parentBranchIndexPath];
            }
        }else{
            BOOL hasMatchedParentKeys = proposed.parentBranchKey == existing.parentBranchKey || [proposed.parentBranchKey isEqualToString:existing.parentBranchKey];
            
            if (!hasMatchedParentKeys) {
                [reloadIndexPaths addObject:parentBranchIndexPath];
            }else{
                id proposedParent = proposed.branches[proposed.parentBranchKey];
                id existingParent = existing.branches[existing.parentBranchKey];
                BOOL hasMatchedParents = proposedParent == existingParent || [proposedParent isEqual:existingParent];
                if (!hasMatchedParents) {
                    [reloadIndexPaths addObject:parentBranchIndexPath];
                }
            }
        }
        
        
    }
    {
        //is valid
        if( proposed.isCurrentBranchValid != existing.isCurrentBranchValid ){
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:BranchTableSectionAddBranch];
            
            if ( proposed.isCurrentBranchValid) {
                [insertIndexPaths addObject:indexPath];
            }else{
                [deleteIndexPaths addObject:indexPath];
            }
            
            [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:self.branchViewModel.branchKeys.count*2 inSection:BranchTableSectionBranches]];
        }
    }

    return @{@"delete":deleteIndexPaths,
             @"insert":insertIndexPaths,
             @"reload":reloadIndexPaths,
             @"reloadSection":reloadSectionIndexSet};
}

-(void)addBranches:(NSArray *)objects{
    
    NSMutableArray* keys = [objects valueForKey:@"key"];
    
    BOOL isLink = [[[NSSet setWithArray:[objects valueForKey:@"parent_branch_key"]] allObjects] isEqualToArray:@[self.branchViewModel.currentBranchKey]];
    
    BranchViewModel* model = [self.branchViewModel copy];
    
    model.parentBranchKey = self.tree.branches[model.branchKeys.firstObject][@"parent_branch_key"];
    if (model.parentBranchKey&& self.tree.branches[model.parentBranchKey] == nil) {
        [self.tree loadBranches:@[model.parentBranchKey]];
    }
    
    if(isLink){
        model.childBranchKeys = keys;
    }
    
    [self updateBranchViewModel:model];
    
    if (isLink && 1 < self.branchViewModel.branchKeys.count) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(2*([self.branchViewModel.branchKeys count]-1)) inSection:BranchTableSectionBranches];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
}


-(void)handleTreeDidUpdateTreeNotification:(NSNotification*)notification{
    if ([self.tree isEqual:notification.object]) {
        if (self.branchViewModel.currentBranchKey == nil) {
            
            BranchViewModel* model = [self.branchViewModel copy];
            model.branchKeys = @[self.tree.data[@"root_branch_key"]];
            
            [self updateBranchViewModel:model];
        }
        
        [self.tree loadChildBranches:self.branchViewModel.currentBranchKey];
    }
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return BranchTableSectionTotal;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger result = 0;
    switch (section) {
        case BranchTableSectionLoadParent:
            result = self.branchViewModel.hasParentBranchKey ? 1 : 0;
            break;
        case BranchTableSectionBranches:
            result = [self.branchViewModel.branchKeys count]*2 + 1;
            break;
        case BranchTableSectionLinks:
            result = [self.branchViewModel.childBranchKeys count] * 2;
            break;
        case BranchTableSectionAddBranch:
            result = self.branchViewModel.isCurrentBranchValid ? 1 : 0;
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
        case BranchTableSectionLoadParent:{
            
            NSString* parentBranch = self.tree.branches[self.branchViewModel.branchKeys.firstObject][@"parent_branch_key"];
            NSDictionary* branchData = self.tree.branches[parentBranch];
            if (branchData == nil) {
                cell.textLabel.text = [NSString stringWithFormat:@"↑"];
            }else{
                cell.textLabel.text = [NSString stringWithFormat:@"↑ %@",branchData[@"link"]];
            }
            break;
        }
        case BranchTableSectionBranches:{
            
            if (indexPath.row < self.branchViewModel.branchKeys.count*2) {
                NSString* branchKey = self.branchViewModel.branchKeys[LinkRow(indexPath)];
                id branch = self.tree.branches[ branchKey ];
                if (IsLinkRow(indexPath)) {
                    LinkTableViewCell* branchCell = (id)cell;
                    branchCell.linkLabel.text = branch[@"link"];
                    branchCell.isLink = NO;
                }else{
                    ContentTableViewCell* branchCell = (id)cell;
                    branchCell.contentLabel.text = branch[@"content"];
                }
            }else{
                if (self.branchViewModel.isCurrentBranchValid) {
                    cell.textLabel.text = @"What happens next?";
                }else{
                    cell.textLabel.text = @"Waiting for additional content";
                }
            }
            break;
        }
        case BranchTableSectionLinks:{
            
            if (IsLinkRow(indexPath) && LinkRow(indexPath) < self.branchViewModel.childBranchKeys.count) {
                id branch = self.tree.branches[ self.branchViewModel.childBranchKeys[LinkRow(indexPath)]];
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
    NSString* key = self.branchViewModel.branchKeys[LinkRow(indexPath)];
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
        case BranchTableSectionLoadParent:
            return @"LoadParentTableViewCell";
            break;
        case BranchTableSectionBranches:
            if (indexPath.row < self.branchViewModel.branchKeys.count*2) {
                if (IsLinkRow(indexPath)) {
                    return @"LinkTableViewCell";
                }else{
                    return @"ContentTableViewCell";
                }
            }else{
                return @"CurrentBranchTextCell";
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
    if ( indexPath.section == BranchTableSectionBranches && self.branchViewModel.branchKeys.count*2 <= indexPath.row ) {
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
        
        NSString* parentBranch = self.tree.branches[self.branchViewModel.branchKeys.firstObject][@"parent_branch_key"];
        
        if (IsNotNull(parentBranch)) {
            [self.tree loadChildBranches:parentBranch];
            
            BranchViewModel* model = [self.branchViewModel copy];
            NSMutableArray* branchKeys = [self.branchViewModel.branchKeys mutableCopy];
            [branchKeys insertObject:parentBranch atIndex:0];
            model.branchKeys = branchKeys;
            NSString* nextParentBranch = self.tree.branches[parentBranch][@"parent_branch_key"];
            
            model.parentBranchKey = [nextParentBranch isEqual:[NSNull null]] ? nil : nextParentBranch;
            [self updateBranchViewModel:model];
            if (model.parentBranchKey != nil) {
                [self.tree loadBranches:@[model.parentBranchKey]];
            }
            
        }
        
    }else if (indexPath.section == BranchTableSectionLinks) {
        if (IsOrRow( indexPath )) {
            return;
        }
        NSString* currentBranchKey = self.branchViewModel.childBranchKeys[LinkRow(indexPath)];
        BranchViewModel* model = [self.branchViewModel copy];
        model.branchKeys = [self.branchViewModel.branchKeys arrayByAddingObject:currentBranchKey];
        model.childBranchKeys = @[];
        [self updateBranchViewModel:model];
        [self.tree loadChildBranches:self.branchViewModel.currentBranchKey];
        //[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionBranches) {
        
        NSUInteger branchIndex = LinkRow(indexPath);
        
        if ([self.branchViewModel.currentBranchKey isEqualToString: self.branchViewModel.branchKeys[branchIndex]]) {
            [self.tree loadChildBranches:self.branchViewModel.currentBranchKey];
            return;
        }
        
        NSString* currentBranchKey = self.branchViewModel.branchKeys[branchIndex];
        
        BranchViewModel* model = [self.branchViewModel copy];
        model.branchKeys = [model.branchKeys subarrayToElement:currentBranchKey];
        model.childBranchKeys = @[];
        [self updateBranchViewModel:model];
        
        [self.tree loadChildBranches:self.branchViewModel.currentBranchKey];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionAddBranch) {
        
        AddBranchStatus status = [self.tree addBranchStatus:self.branchViewModel.currentBranchKey];
        
        switch (status) {
            case AddBranchStatusAllowed:{
                [self performSegueWithIdentifier:@"BranchForm" sender:@{@"parentBranchKey":self.branchViewModel.currentBranchKey,@"tree":self.tree}];
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


- (IBAction)didTapInfoButton:(id)sender{
    NSString* editButtonTitle = nil;
    
    if([AuthenticationManager instance].isLoggedIn && [self.tree isModerator]){
        editButtonTitle = @"Edit";
    }
    
    NSString* moderatorName = self.tree.data[@"moderatorname"];
    
    NSString* title = [NSString stringWithFormat:@"%@ moderated by %@",self.tree.treeName,moderatorName];
    
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"About", @"Activity",moderatorName, editButtonTitle, nil];
    actionSheet.tag = -1;
    [actionSheet showInView:self.view];
}


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    if (actionSheet.tag < 0) {
        NSString* title = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        NSString* moderatorName = self.tree.data[@"moderatorname"];
        if ([title isEqualToString:moderatorName]) {
            [self performSegueWithIdentifier:@"UserView" sender:moderatorName];
        }else if ([title isEqualToString:@"About"]) {
            [self performSegueWithIdentifier:@"About" sender:nil];
        }else if ([title isEqualToString:@"Activity"]) {
            [self performSegueWithIdentifier:@"TreeActivity" sender:nil];
        }else if ([title isEqualToString:@"Edit"]) {
            [self performSegueWithIdentifier:@"TreeForm" sender:nil];
        }
        
    }else if (actionSheet.tag < self.branchViewModel.branchKeys.count) {
        NSString* key = self.branchViewModel.branchKeys[actionSheet.tag];
        
        id branch = self.tree.branches[ key ];
        
        if (branch != nil) {
            NSString* title = [actionSheet buttonTitleAtIndex:buttonIndex];
            
            if ([title isEqualToString:@"Delete"]) {
                [[[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Are you sure you want to delete this branch?" cancelButtonTitle:@"Keep it" otherButtonTitles:@[@"Delete it"] block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex == 1) {
                        NSDictionary * branch = self.tree.branches[self.branchViewModel.currentBranchKey];
                        
                        BranchViewModel* model = self.branchViewModel;
                        model.branchKeys = [model.branchKeys arrayByPop];
                        [self updateBranchViewModel:model];
                        
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
    
    NSString* branchKey = branches.firstObject[@"key"];
    
    BranchViewModel* model = [self.branchViewModel copy];
    model.branchKeys = [self.branchViewModel.branchKeys arrayByPush:branchKey];
    model.childBranchKeys = @[];
    
    [self updateBranchViewModel:model];
    
    [self.tree loadChildBranches:self.branchViewModel.currentBranchKey];
    
}

#pragma UIKeyboard


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"About"]) {
        UIViewController<Queryable>* controller = segue.destinationViewController;
        controller.query = @{@"tree":self.tree.treeName, @"about":self.tree.conventions};
        controller.title = self.tree.treeName;
    }
    if ([segue.identifier isEqualToString:@"TreeActivity"]) {
        UIViewController<Queryable>* controller = segue.destinationViewController;
        controller.query = @{@"tree_name":self.tree.treeName};
        controller.title = self.tree.treeName;
    }
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

@implementation NSArray(Constructors)

-(NSArray*)arrayByShift{
    NSMutableArray* array = [self mutableCopy];
    [array removeObjectAtIndex:0];
    return array;
}

-(NSArray*)arrayByUnshift:(id)object{
    NSMutableArray* array = [self mutableCopy];
    [array insertObject:object atIndex:0];
    return array;
}

-(NSArray*)arrayByPop{
    return [self subarrayWithRange:NSMakeRange(0, self.count-1)];
}

-(NSArray*)arrayByPush:(id)object{
    return [self arrayByAddingObject:object];
}
//a subarray up to and including the element
-(NSArray*)subarrayToElement:(id)object{
    NSParameterAssert([self containsObject:object]);
    NSUInteger index = [self indexOfObject:object];
    return [self subarrayWithRange:NSMakeRange(0, index+1)];
}

@end
