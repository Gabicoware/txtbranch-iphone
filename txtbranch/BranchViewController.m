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

#define IsOrRow(indexPath) (indexPath.row%2 == 1)
#define IsLinkRow(indexPath) (indexPath.row%2 == 0)
#define LinkRow(indexPath) (indexPath.row/2)
//AboutHiddenTableViewCell

NS_ENUM(NSInteger, BranchTableSection){
    BranchTableSectionAbout,
    BranchTableSectionLoadParent,
    BranchTableSectionBranches,
    BranchTableSectionLinks,
    BranchTableSectionAddBranch,
    BranchTableSectionAddBranchForm,
    BranchTableSectionTotal
};

#define IsNotNull(object) (![[NSNull null] isEqual:object] && object != nil)

@interface BranchViewController ()<UITableViewDataSource,UITableViewDelegate,TTTAttributedLabelDelegate>

@property (nonatomic, assign) BOOL needsParentBranch;
@property (nonatomic,strong) ASIHTTPRequest* request;
@property (nonatomic,strong) IBOutlet UITableView* tableView;
@property (nonatomic,strong) IBOutlet UIBarButtonItem* editItem;
@property (nonatomic,strong) Tree* tree;

@property (nonatomic, strong) NSString* currentBranchKey;

-(CGRect)addBranchFormRect;

@end

@implementation BranchViewController{
    NSString* _branchKey;
    NSMutableArray* _branchKeys;
    NSArray* _childBranchKeys;
    BOOL _isAboutHidden;
    BOOL _isAddBranchFormShowing;
    NSMutableDictionary* _cells;
    NSString* _currentBranchKey;
    BOOL _isEditing;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateSize:) name:AddBranchFormTableViewCellUpdateSizeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBranchFormCancel:) name:AddBranchFormTableViewCellCancelNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBranchFormSave:) name:AddBranchFormTableViewCellSaveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTreeDidUpdateBranchesNotification:) name:TreeDidUpdateBranchesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTreeDidUpdateTreeNotification:) name:TreeDidUpdateTreeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTreeDidAddBranchesNotification:) name:TreeDidAddBranchesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardUpdate:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardUpdate:) name:UIKeyboardWillChangeFrameNotification object:nil];
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
    
    if (query[@"branch"]) {
        self.currentBranchKey = query[@"branch"];
        [self.tree loadBranches:@[query[@"branch"]]];
    }
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
    
    CGRect formRect = [self addBranchFormRect];
    
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
            [reloadedArray addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionBranches]];
        }
        [keys addObject:branch[@"key"]];
        if (![branch[@"parent_branch"] isEqual:_currentBranchKey]) {
            isLink = NO;
        }
    }
    NSString* parentBranch = self.tree.branches[_branchKeys.firstObject][@"parent_branch"];
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
    
    [reloadedArray addObject:[NSIndexPath indexPathForRow:_branchKeys.count inSection:BranchTableSectionBranches]];
    
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
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:([_branchKeys count]-1) inSection:BranchTableSectionBranches];
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
            result = [_branchKeys count] + 1;
            break;
        case BranchTableSectionLinks:
            if (!_isAddBranchFormShowing) {
                result = [_childBranchKeys count] * 2;
            }
            break;
        case BranchTableSectionAddBranch:
            result = _isAddBranchFormShowing ? 0 : 1;
            break;
        case BranchTableSectionAddBranchForm:
            result = _isAddBranchFormShowing ? 1 : 0;
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
            
            NSString* parentBranch = self.tree.branches[_branchKeys.firstObject][@"parent_branch"];
            NSDictionary* branchData = self.tree.branches[parentBranch];
            if (branchData == nil) {
                cell.textLabel.text = [NSString stringWithFormat:@"↑"];
            }else{
                cell.textLabel.text = [NSString stringWithFormat:@"↑ %@",branchData[@"link"]];
            }
            break;
        }
        case BranchTableSectionBranches:{
            
            if (indexPath.row < _branchKeys.count) {
                NSString* branchKey = _branchKeys[indexPath.row];
                id branch = self.tree.branches[ branchKey ];
                if (_isEditing && [branchKey isEqualToString:_currentBranchKey]) {
                    AddBranchFormTableViewCell* formCell = (id)cell;
                    [formCell setupWithBranch:branch];
                    [formCell setupWithTree:self.tree];
                }else{
                    BranchTableViewCell* branchCell = (id)cell;
                    branchCell.linkLabel.text = branch[@"link"];
                    branchCell.contentLabel.text = branch[@"content"];
                    branchCell.isLink = NO;
                }
            }else{
                BranchMetadataTableViewCell* metadataCell = (id)cell;
                metadataCell.bylineLabel.delegate = self;
                metadataCell.editButton.delegate = self;
                metadataCell.deleteButton.delegate = self;
                id branch = self.tree.branches[ _branchKeys.lastObject];
                
                if (branch == nil) {
                    metadataCell.bylineLabel.text = @"";
                }else{
                    
                    
                    NSDictionary* normalAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-LightItalic" size:15],
                                                       NSForegroundColorAttributeName:[UIColor darkGrayColor]};
                    
                    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] initWithString:@"" attributes:normalAttributes];
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"by " attributes:normalAttributes]];
                    
                    
                    NSDictionary* params = @{@"itemType": @"username",
                                             @"username": branch[@"authorname"]};
                    NSString* queryString = [params queryStringValue];
                    NSDictionary* linkAttributes = [self linkAttributesWithURLString:[NSString stringWithFormat:@"txtbranch://?%@",queryString]];
                    
                    [string appendAttributedString:[[NSAttributedString alloc] initWithString:branch[@"authorname"] attributes:linkAttributes]];
                    metadataCell.bylineLabel.text = [string copy];
                }
                
                
                BOOL canEdit = [self.tree canEditBranch:_branchKeys.lastObject];
                BOOL canDelete = [self.tree canDeleteBranch:_branchKeys.lastObject];
                
                metadataCell.editButton.hidden = !canEdit || _isEditing;
                NSDictionary* editLinkAttributes = [self linkAttributesWithURLString:@"txtbranch://?itemType=edit"];
                metadataCell.editButton.text = [[NSAttributedString alloc] initWithString:@"edit" attributes:editLinkAttributes];
                
                metadataCell.deleteButton.hidden = !canDelete || _isEditing;
                NSDictionary* deleteLinkAttributes = [self linkAttributesWithURLString:@"txtbranch://?itemType=delete"];
                metadataCell.deleteButton.text = [[NSAttributedString alloc] initWithString:@"delete" attributes:deleteLinkAttributes];
            }
            break;
        }
        case BranchTableSectionLinks:{
            
            if (IsLinkRow(indexPath) && LinkRow(indexPath) < _childBranchKeys.count) {
                id branch = self.tree.branches[ _childBranchKeys[LinkRow(indexPath)]];
                BranchTableViewCell* branchCell = (id)cell;
                branchCell.linkLabel.text = branch[@"link"];
                branchCell.contentLabel.text = branch[@"content"];
                branchCell.isLink = YES;
            }
            
            break;
        }
        case BranchTableSectionAddBranchForm:{
            AddBranchFormTableViewCell* formCell = (id)cell;
            [formCell setupWithTree:self.tree];
            break;
        }
    }
}

-(NSDictionary*)linkAttributesWithURLString:(NSString*)URLString{
    NSURL* URL = [NSURL URLWithString:URLString];
    NSDictionary* editLinkAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Italic" size:15],
                                         NSLinkAttributeName:URL,
                                         NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    return editLinkAttributes;
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
            if (indexPath.row < _branchKeys.count) {
                
                NSString* branchKey = _branchKeys[indexPath.row];
                if (_isEditing && [branchKey isEqualToString:_currentBranchKey]) {
                    return @"AddBranchFormTableViewCell";
                }else{
                    return @"BranchTableViewCell";
                }
                
            }else{
                return @"CurrentBranchMedatataCell";
            }
            break;
        case BranchTableSectionLinks:
            if (IsOrRow(indexPath)) {
                return @"OrTableViewCell";
            }else{
                return @"BranchTableViewCell";
            }
            break;
        case BranchTableSectionAddBranch:
            return @"AddBranchTableViewCell";
            break;
        case BranchTableSectionAddBranchForm:
            return @"AddBranchFormTableViewCell";
            break;
            
    }
    return nil;
}

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ( indexPath.section == BranchTableSectionBranches && _branchKeys.count <= indexPath.row ) {
        return nil;
    }else if(_isEditing && indexPath.section == BranchTableSectionBranches && _branchKeys.count - 1 == indexPath.row){
        return nil;
    }else if(_isAddBranchFormShowing && indexPath.section == BranchTableSectionAddBranchForm){
        return nil;
    }else if(indexPath.section == BranchTableSectionLinks && IsOrRow(indexPath)){
        return nil;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == BranchTableSectionLoadParent) {
        
        NSString* parentBranch = self.tree.branches[_branchKeys.firstObject][@"parent_branch"];
        
        if (IsNotNull(parentBranch)) {
            [self.tree loadChildBranches:parentBranch];
            [_branchKeys insertObject:parentBranch atIndex:0];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:BranchTableSectionBranches]] withRowAnimation:UITableViewRowAnimationFade];
            
            NSString* nextParentBranch = self.tree.branches[parentBranch][@"parent_branch"];
            
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
        NSIndexPath* newBranchIndexPath = [NSIndexPath indexPathForRow:[_branchKeys count] inSection:BranchTableSectionBranches];
        [_branchKeys addObject:_currentBranchKey];
        NSMutableArray* links = [NSMutableArray array];
        for (int row = 0; row < _childBranchKeys.count*2; row++) {
            if (row != indexPath.row) {
                [links addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionLinks]];
            }
        }
        _childBranchKeys = nil;
        
        BranchTableViewCell* cell = (BranchTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.isLink = NO;
        [tableView beginUpdates];
        [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newBranchIndexPath];
        [self.tableView deleteRowsAtIndexPaths:links withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        [self.tree loadChildBranches:_currentBranchKey];
        //[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionBranches) {
        if ([_currentBranchKey isEqualToString: _branchKeys[indexPath.row]]) {
            [self.tree loadChildBranches:_currentBranchKey];
            return;
        }
        _currentBranchKey = _branchKeys[indexPath.row];
        NSRange range = NSMakeRange(indexPath.row+1, _branchKeys.count - indexPath.row-1);
        NSMutableArray* indexes = [@[] mutableCopy];
        for (NSInteger index = range.location; index < range.length + range.location; index++) {
            [indexes addObject:[NSIndexPath indexPathForRow:index inSection:BranchTableSectionBranches]];
        }
        [_branchKeys removeObjectsInRange:range];
        [tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
        _childBranchKeys = nil;
        [self.tree loadChildBranches:_currentBranchKey];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionAddBranch) {
        
        AddBranchStatus status = [self.tree addBranchStatus:_currentBranchKey];
        
        switch (status) {
            case AddBranchStatusAllowed:{
                [self setAddBranchFormShowing:YES];
                [self scrollToForm];
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

-(CGRect)addBranchFormRect{
    if (_isAddBranchFormShowing) {
        NSIndexPath* formPath = [NSIndexPath indexPathForRow:0 inSection:BranchTableSectionAddBranchForm];
        return [self.tableView rectForRowAtIndexPath:formPath];
    }
    return CGRectNull;
}

-(void)scrollToForm{
    if (_isAddBranchFormShowing) {
        NSIndexPath* formPath = [NSIndexPath indexPathForRow:0 inSection:BranchTableSectionAddBranchForm];
        [self.tableView scrollToRowAtIndexPath:formPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(void)handleUpdateSize:(NSNotification*)notification{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

-(void)handleBranchFormCancel:(NSNotification*)notification{
    if (_isEditing) {
        [self setIsEditing:NO];
    }else{
        [self setAddBranchFormShowing:NO];
    }
}

-(void)handleBranchFormSave:(NSNotification*)notification{
    AddBranchFormTableViewCell* cell = notification.object;
    
    NSMutableDictionary* branch = nil;
    
    if (_isEditing) {
        
        branch = [self.tree.branches[ _currentBranchKey ] mutableCopy];
        ((NSMutableDictionary*)branch)[@"content"] = cell.contentTextView.text;
        ((NSMutableDictionary*)branch)[@"link"] = cell.linkTextView.text;
        
    }else{
        branch = [@{@"link": cell.linkTextView.text,
                                 @"content":cell.contentTextView.text,
                                 @"parent_branch_key":_currentBranchKey} mutableCopy];
    }
    
    SaveBranchStatus status = [self.tree saveBranchStatus:branch];
    
    if (status == 0) {
        
        if (_isEditing) {
            //do this shiznit
            [self.tree editBranch:branch];
            [self setIsEditing:NO];
        }else{
            [self.tree addBranch:branch];
        }
        
    }else{
        NSMutableString* message = [@"There are was an issue trying to save. " mutableCopy];
        
        if (status & SaveBranchStatusEmptyContent) {
            [message appendString:@"The content cannot be empty. "];
        }
        if (status & SaveBranchStatusEmptyLink) {
            [message appendString:@"The link cannot be empty. "];
        }
        if (status & SaveBranchStatusModeratorOnlyContent) {
            [message appendString:@"The content is moderator only. "];
        }
        if (status & SaveBranchStatusModeratorOnlyLink) {
            [message appendString:@"The link can only be saved by the moderator. "];
        }
        
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
    
    
    
}

-(void)handleTreeDidAddBranchesNotification:(NSNotification*)notification{
    [self setAddBranchFormShowing:NO];
    
    NSArray * branches = notification.userInfo[TreeNotificationBranchesUserInfoKey];
    
    _currentBranchKey = branches.firstObject[@"key"];
    [_branchKeys addObject:_currentBranchKey];
    _childBranchKeys = nil;
    [self.tableView reloadData];
    
    [self.tree loadChildBranches:_currentBranchKey];
    
}

-(void)setIsEditing:(BOOL)isEditing{
    _isEditing = isEditing;
    [self.tableView beginUpdates];
    
    NSArray* indexPaths = @[[NSIndexPath indexPathForRow:(_branchKeys.count - 1) inSection:BranchTableSectionBranches],
                            [NSIndexPath indexPathForRow:(_branchKeys.count) inSection:BranchTableSectionBranches]];
    
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

-(void)setAddBranchFormShowing:(BOOL)addBranchFormShowing{
    _isAddBranchFormShowing = addBranchFormShowing;
    NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(BranchTableSectionLinks, BranchTableSectionTotal - BranchTableSectionLinks)];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma UIKeyboard

-(void)handleKeyboardNotification:(NSNotification*)notification{
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[AddBranchFormTableViewCell class]]) {
            AddBranchFormTableViewCell* formCell = (id)cell;
            if(formCell.linkTextView.isFirstResponder){
                [self centerTextView:formCell.contentTextView];
            }
            if (formCell.contentTextView.isFirstResponder) {
                [self centerTextView:formCell.contentTextView];
            }
            
        }
    }
}

-(void)centerTextView:(UITextView*)textView{
    UITextRange * selectionRange = [textView selectedTextRange];
    CGRect selectionStartRect = [textView caretRectForPosition:selectionRange.start];
    CGRect selectionEndRect = [textView caretRectForPosition:selectionRange.end];
    CGPoint selectionCenterPoint = (CGPoint){(selectionStartRect.origin.x + selectionEndRect.origin.x)/2,(selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
    
    CGPoint point = [self.tableView convertPoint:selectionCenterPoint fromView:textView];
    
    
    if (!CGRectContainsPoint( CGRectInset( self.tableView.bounds, 0, 30) , point )) {
        
        CGPoint offsetPoint = CGPointZero;
        offsetPoint.y = point.y - self.tableView.bounds.size.height*0.66666;
        
        [self.tableView setContentOffset:offsetPoint animated:YES];
    }
    
}

#pragma mark TTTAttributedLabelDelegate methods

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url{
    
    NSDictionary* queryParams = [NSDictionary dictionaryWithQueryString:[url query]];
    
    if([queryParams[@"itemType"] isEqualToString:@"delete"]){
        [[[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Are you sure you want to delete this branch?" cancelButtonTitle:@"Keep it" otherButtonTitles:@[@"Delete it"] block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                NSDictionary * branch = self.tree.branches[_currentBranchKey];
                
                [_branchKeys removeLastObject];
                _currentBranchKey = [_branchKeys lastObject];
                [self.tableView reloadData];
                [self.tree deleteBranch:branch];
            }
        }] show];
    }else if([queryParams[@"itemType"] isEqualToString:@"edit"]){
        [self setIsEditing:YES];
    }else if([queryParams[@"itemType"] isEqualToString:@"username"]){
        
        NSString* authorname = self.tree.branches[_currentBranchKey][@"authorname"];
        [self performSegueWithIdentifier:@"OpenNotifications" sender:authorname];
        
    }
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"OpenNotifications"] && [sender isKindOfClass:[NSString class]]) {
        id<Queryable> controller = segue.destinationViewController;
        controller.query = @{@"from_username":sender};
    }
    if ([segue.identifier isEqualToString:@"TreeForm"]) {
        UINavigationController* navController = segue.destinationViewController;
        id<Queryable> controller = [[navController viewControllers] firstObject];
        controller.query = self.query;
    }
    
}


@end
