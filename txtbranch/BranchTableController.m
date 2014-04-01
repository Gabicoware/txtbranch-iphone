//
//  BranchTableController.m
//  txtbranch
//
//  Created by Daniel Mueller on 2/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchTableController.h"
#import "BranchTableViewCell.h"
#import "TBTextView.h"
#import "AuthenticationManager.h"

//AboutHiddenTableViewCell

NS_ENUM(NSInteger, BranchTableSection){
    BranchTableSectionAbout,
    BranchTableSectionBranches,
    BranchTableSectionLinks,
    BranchTableSectionAddBranch,
    BranchTableSectionAddBranchForm,
    BranchTableSectionTotal
};

@interface BranchTableController()<UITableViewDataSource,UITableViewDelegate>{
    NSDictionary* _branch;
}

@end

@implementation BranchTableController{
    NSMutableArray* _branchKeys;
    NSArray* _childBranchKeys;
    BOOL _isAboutHidden;
    BOOL _isAddBranchFormShowing;
    NSMutableDictionary* _cells;
    NSMutableDictionary* _branches;
    NSString* _currentBranchKey;
    BOOL _isEditing;
}

-(instancetype)initWithTableView:(UITableView*)tableView{
    if ((self = [self init]))
    {
        tableView.delegate = self;
        tableView.dataSource = self;
        self.tableView = tableView;
        _cells = [NSMutableDictionary dictionary];
        _branches = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateSize:) name:AddBranchFormTableViewCellUpdateSizeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBranchFormCancel:) name:AddBranchFormTableViewCellCancelNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBranchFormSave:) name:AddBranchFormTableViewCellSaveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardWillShowNotification object:nil];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)addBranches:(NSArray *)objects{
    
    NSMutableArray* keys = [NSMutableArray array];
    
    NSMutableArray* reloadedArray = [NSMutableArray array];
    
    BOOL isNotLink = NO;
    
    for (NSDictionary* branch in objects) {
        _branches[branch[@"key"]] = branch;
        NSInteger row = [_branchKeys indexOfObject:branch[@"key"]];
        if (row != NSNotFound) {
            [reloadedArray addObject:[NSIndexPath indexPathForRow:row inSection:BranchTableSectionBranches]];
        }
        [keys addObject:branch[@"key"]];
        if (![branch[@"parent_branch"] isEqual:_currentBranchKey]) {
            isNotLink = YES;
        }
    }
    [reloadedArray addObject:[NSIndexPath indexPathForRow:_branchKeys.count inSection:BranchTableSectionBranches]];
    
    if(!isNotLink){
        _childBranchKeys = keys;
    }
    [self.tableView beginUpdates];
    
    [self.tableView reloadRowsAtIndexPaths:reloadedArray
                          withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:BranchTableSectionLinks]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
    
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:([_branchKeys count]-1) inSection:BranchTableSectionBranches];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

}

-(void)setTree:(NSDictionary *)tree{
    _tree = tree;
    _currentBranchKey = tree[@"root_branch_key"];
    _branchKeys = [@[_currentBranchKey] mutableCopy];
    [self.tableView reloadData];
    [self.delegate tableController:self didOpenBranchKey:_currentBranchKey];
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
        case BranchTableSectionBranches:
            result = [_branchKeys count] + 1;
            break;
        case BranchTableSectionLinks:
            if (!_isAddBranchFormShowing) {
                result = [_childBranchKeys count];
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
            headerCell.aboutLabel.text = self.tree[@"conventions"];
            headerCell.isAboutHidden = _isAboutHidden;
            break;
        }
        case BranchTableSectionBranches:{
            
            if (indexPath.row < _branchKeys.count) {
                NSString* branchKey = _branchKeys[indexPath.row];
                id branch = _branches[ branchKey ];
                if (_isEditing && [branchKey isEqualToString:_currentBranchKey]) {
                    AddBranchFormTableViewCell* formCell = (id)cell;
                    [formCell setupWithBranch:branch];
                }else{
                    BranchTableViewCell* branchCell = (id)cell;
                    branchCell.linkLabel.text = branch[@"link"];
                    branchCell.contentLabel.text = branch[@"content"];
                }
            }else{
                BranchMetadataTableViewCell* metadataCell = (id)cell;
                id branch = _branches[ _branchKeys.lastObject];
                NSString* bylineString = [NSString stringWithFormat:@"by %@",branch[@"authorname"]];
                [metadataCell.bylineButton setTitle:bylineString forState:UIControlStateNormal];
                
                NSString* username = [AuthenticationManager instance].username;
                
                BOOL canEdit = [username isEqualToString:branch[@"authorname"]] || [username isEqualToString:self.tree[@"moderatorname"]];
                
                metadataCell.editButton.hidden = !canEdit;
                
                BOOL canDelete = canEdit && _childBranchKeys != nil && _childBranchKeys.count == 0;
                metadataCell.deleteButton.hidden = !canDelete;
                
                [metadataCell.editButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                [metadataCell.editButton addTarget:self action:@selector(didTapEditButton:) forControlEvents:UIControlEventTouchUpInside];
                [metadataCell.deleteButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                [metadataCell.deleteButton addTarget:self action:@selector(didTapDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
                
            }
            break;
        }
        case BranchTableSectionLinks:{
            LinkTableViewCell* linkCell = (id)cell;
            id branch = _branches[ _childBranchKeys[indexPath.row]];
            linkCell.linkLabel.text = branch[@"link"];
            break;
        }
    }
}

-(void)didTapEditButton:(id)sender{
    [self setIsEditing:YES];
}

-(void)didTapDeleteButton:(id)sender{
    [[[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"Are you sure you want to delete this branch?" delegate:self cancelButtonTitle:@"Keep it" otherButtonTitles:@"Delete it", nil] show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        NSDictionary * branch = _branches[_currentBranchKey];
        
        [_branchKeys removeLastObject];
        _currentBranchKey = [_branchKeys lastObject];
        [self.tableView reloadData];
        [self.delegate tableController:self deleteBranch:branch];
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
    return [cell sizeThatFits:tableView.bounds.size].height;
}

-(NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch ([indexPath section]) {
        case BranchTableSectionAbout:
            return @"AboutTableViewCell";
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
            return @"LinkTableViewCell";
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == BranchTableSectionAbout) {
        _isAboutHidden = !_isAboutHidden;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        //update the current cell
        AboutTableViewCell* cell = (id)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:BranchTableSectionAbout]];
        cell.isAboutHidden = _isAboutHidden;
        //update the heights
        [tableView beginUpdates];
        [tableView endUpdates];
    }else if (indexPath.section == BranchTableSectionLinks) {
        _currentBranchKey = _childBranchKeys[indexPath.row];
        [_branchKeys addObject:_currentBranchKey];
        [tableView beginUpdates];
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:([_branchKeys count]-1) inSection:BranchTableSectionBranches];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        NSIndexPath* updatedIndexPath = [NSIndexPath indexPathForRow:[_branchKeys count] inSection:BranchTableSectionBranches];
        [tableView insertRowsAtIndexPaths:@[updatedIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        _childBranchKeys = nil;
        [self.delegate tableController:self didOpenBranchKey:_currentBranchKey];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }else if (indexPath.section == BranchTableSectionBranches) {
        _currentBranchKey = _branchKeys[indexPath.row];
        NSRange range = NSMakeRange(indexPath.row+1, _branchKeys.count - indexPath.row-1);
        NSMutableArray* indexes = [@[] mutableCopy];
        for (NSInteger index = range.location; index < range.length + range.location; index++) {
            [indexes addObject:[NSIndexPath indexPathForRow:index inSection:BranchTableSectionBranches]];
        }
        [_branchKeys removeObjectsInRange:range];
        [tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
        _childBranchKeys = nil;
        [self.delegate tableController:self didOpenBranchKey:_currentBranchKey];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }else if (indexPath.section == BranchTableSectionAddBranch) {
        
        AddBranchStatus status = [self.delegate tableController:self statusForBranchKey:_currentBranchKey];
        
        switch (status) {
            case AddBranchStatusAllowed:{
                [self setAddBranchFormShowing:YES];
                [self scrollToForm];
                break;
            }
            case AddBranchStatusNeedsLogin:{
                break;
            }
            case AddBranchStatusHasBranches:{
                break;
            }
                
                
        }
    }
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
    
    if (_isEditing) {
        //do this shiznit
        NSMutableDictionary* branch = [_branches[ _currentBranchKey ] mutableCopy];
        branch[@"content"] = cell.contentTextView.text;
        branch[@"link"] = cell.linkTextView.text;
        [self.delegate tableController:self editBranch:branch];
        
        [self setIsEditing:NO];
        
    }else{
        NSDictionary* branch = @{@"link": cell.linkTextView.text,
                                 @"content":cell.contentTextView.text,
                                 @"parent_branch_key":_currentBranchKey};
        [self.delegate tableController:self addBranch:branch];
        
    }
    
    
}

-(void)setIsEditing:(BOOL)isEditing{
    _isEditing = isEditing;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(_branchKeys.count - 1) inSection:BranchTableSectionBranches]] withRowAnimation:UITableViewRowAnimationFade];
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
    
    CGPoint offsetPoint = CGPointZero;
    offsetPoint.y = point.y - 120.0;
    
    
    [self.tableView setContentOffset:offsetPoint animated:YES];
    
}

@end
