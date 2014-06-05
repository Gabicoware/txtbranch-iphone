//
//  BranchFormViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/22/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "BranchFormViewController.h"
#import "TBTextView.h"
#import "Tree.h"
#import "UIAlertView+Block.h"

//for when the size of the cell needs to update
extern NSString* BranchFormTableViewCellUpdateSizeNotification;

@interface BranchFormTableViewCell : UITableViewCell<UITextViewDelegate>

@property (nonatomic,weak) IBOutlet TBTextView* linkTextView;
@property (nonatomic,weak) IBOutlet TBTextView* contentTextView;
@property (nonatomic,weak) IBOutlet UILabel* countLabel;

-(void)setupWithBranch:(NSDictionary*)branch;
-(void)setupWithTree:(Tree*)tree;

@end

@interface BranchFormViewController()

-(IBAction)didTapCancelButton:(id)sender;
-(IBAction)didTapSaveButton:(id)sender;

@property (nonatomic,weak) BranchFormTableViewCell* cell;
@property (nonatomic,readonly) NSString* branchKey;
@property (nonatomic,readonly) NSString* parentBranchKey;

@property (nonatomic,strong) NSDictionary* unsavedBranch;

@property (nonatomic,readonly) Tree* tree;

@end


@implementation BranchFormViewController{
    BOOL _needsConfirmation;
}
@synthesize query=_query;

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setupNotifications];
    if (self.branchKey) {
        self.title = @"Edit Branch";
    }else{
        self.title = @"Add a Branch";
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.cell.linkTextView becomeFirstResponder];
}

-(void)setQuery:(NSDictionary *)query{
    _query = query;
    self.unsavedBranch = [self.tree getUnsavedBranchForQuery:self.query];
    [self.tree deleteUnsavedBranchForQuery:self.query];
    _needsConfirmation = self.unsavedBranch != nil;
    if (_needsConfirmation) {
        [[[UIAlertView alloc] initWithTitle:@"Restore Branch?"
                                    message:@"You have an unsaved branch would you like to use it? Otherwise it will be deleted."
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@[@"Yes"]
                                      block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                          if ( buttonIndex == 0 ) {
                                              self.unsavedBranch = nil;
                                          }
                                          _needsConfirmation = NO;
                                          [self.tableView reloadData];
        }] show];
    }
}

-(NSString*)branchKey{
    return self.query[@"branchKey"];
}
-(NSString*)parentBranchKey{
    return self.query[@"parentBranchKey"];
}
-(NSString*)tree{
    return self.query[@"tree"];
}

-(void)handleUpdateSize:(NSNotification*)notification{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

-(void)setupNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdateSize:) name:BranchFormTableViewCellUpdateSizeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardDidShowNotification object:nil];
}

-(IBAction)didTapCancelButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(IBAction)didTapSaveButton:(id)sender{
    NSMutableDictionary* branch = nil;
    
    if (self.branchKey != nil) {
        
        branch = [self.tree.branches[ self.branchKey ] mutableCopy];
        ((NSMutableDictionary*)branch)[@"content"] = self.cell.contentTextView.text;
        ((NSMutableDictionary*)branch)[@"link"] = self.cell.linkTextView.text;
        
    }else{
        branch = [@{@"link": self.cell.linkTextView.text,
                    @"content":self.cell.contentTextView.text,
                    @"parent_branch_key":self.parentBranchKey} mutableCopy];
    }
    
    SaveBranchStatus status = [self.tree saveBranchStatus:branch];
    
    if (status == 0) {
        
        if (self.branchKey) {
            [self.tree editBranch:branch];
        }else{
            [self.tree addBranch:branch];
        }
        [self dismissViewControllerAnimated:YES completion:NULL];
        
    }else{
        NSMutableString* message = [@"There are was an issue trying to save. " mutableCopy];
        
        if (status & SaveBranchStatusEmptyContent) {
            [message appendString:@"The content cannot be empty. "];
        }
        if (status & SaveBranchStatusTooLongContent) {
            [message appendString:@"The content has too many characters. "];
        }
        if (status & SaveBranchStatusEmptyLink) {
            [message appendString:@"The link cannot be empty. "];
        }
        if (status & SaveBranchStatusTooLongLink) {
            [message appendString:@"The link has too many characters. "];
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

-(void)handleKeyboardNotification:(NSNotification*)notification{
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[BranchFormTableViewCell class]]) {
            BranchFormTableViewCell* formCell = (id)cell;
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



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _needsConfirmation ? 0 : 1 ;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return self.cell;
}

-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ( self.cell.frame.size.width != tableView.bounds.size.width ) {
        CGRect frame = self.cell.frame;
        frame.size.width = tableView.bounds.size.width;
        self.cell.frame = frame;
        [self.cell layoutSubviews];
    }
    return [self.cell sizeThatFits:tableView.bounds.size].height;
    
}

-(BranchFormTableViewCell*)cell{
    if (_cell == nil) {
        _cell = [self.tableView dequeueReusableCellWithIdentifier:@"BranchFormTableViewCell"];
        [_cell setupWithTree:self.tree];
        id branch = self.unsavedBranch;
        if (branch == nil && self.branchKey) {
            branch = self.tree.branches[self.branchKey];
        }
        if (branch) {
            [_cell setupWithBranch:branch];
        }
        [self.cell layoutSubviews];
    }
    return _cell;
}

@end

NSString* BranchFormTableViewCellUpdateSizeNotification = @"BranchFormTableViewCellUpdateSizeNotification";


@interface BranchFormTableViewCell()

@property (nonatomic,strong) NSMutableDictionary* currentBranch;
@property (nonatomic,assign) NSUInteger linkMax;
@property (nonatomic,assign) NSUInteger contentMax;

@end

@implementation BranchFormTableViewCell

-(CGSize)sizeThatFits:(CGSize)size{
    if (![self.linkTextView.text isEqualToString:self.currentBranch[@"link"]]) {
        self.linkTextView.text = self.currentBranch[@"link"];
        [self.linkTextView layoutSubviews];
    }
    if (![self.contentTextView.text isEqualToString:self.currentBranch[@"content"]]) {
        self.contentTextView.text = self.currentBranch[@"content"];
        [self.contentTextView layoutSubviews];
    }
    
    CGSize selfSize = self.frame.size;
    
    CGFloat linkHeightDiff = 0.0;
    if (![self.linkTextView.text isEqualToString:@""]) {
        linkHeightDiff = self.linkTextView.contentSize.height - self.linkTextView.frame.size.height;
    }else{
        linkHeightDiff = self.linkTextView.placeholderSize.height - self.linkTextView.frame.size.height;
    }
    
    CGFloat contentHeightDiff = 0.0;
    if (![self.contentTextView.text isEqualToString:@""]) {
        contentHeightDiff = self.contentTextView.contentSize.height - self.contentTextView.frame.size.height;
    }else{
        contentHeightDiff = self.contentTextView.placeholderSize.height - self.contentTextView.frame.size.height;
    }
    
    selfSize.height += linkHeightDiff;
    selfSize.height += contentHeightDiff;
    
    return selfSize;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (![self.linkTextView.text isEqualToString:self.currentBranch[@"link"]]) {
        self.linkTextView.text = self.currentBranch[@"link"];
        [self.linkTextView layoutSubviews];
    }
    if (![self.contentTextView.text isEqualToString:self.currentBranch[@"content"]]) {
        self.contentTextView.text = self.currentBranch[@"content"];
        [self.contentTextView layoutSubviews];
    }
    
    
    CGFloat linkHeightDiff = 0.0;
    if (![self.linkTextView.text isEqualToString:@""]) {
        linkHeightDiff = self.linkTextView.contentSize.height - self.linkTextView.frame.size.height;
    }else{
        linkHeightDiff = self.linkTextView.placeholderSize.height - self.linkTextView.frame.size.height;
    }
    
    CGFloat contentHeightDiff = 0.0;
    if (![self.contentTextView.text isEqualToString:@""]) {
        contentHeightDiff = self.contentTextView.contentSize.height - self.contentTextView.frame.size.height;
    }else{
        contentHeightDiff = self.contentTextView.placeholderSize.height - self.contentTextView.frame.size.height;
    }
    
    
    CGRect linkTextViewFrame = self.linkTextView.frame;
    CGRect contentTextViewFrame = self.contentTextView.frame;
    
    contentTextViewFrame.origin.y = contentTextViewFrame.origin.y + linkHeightDiff;
    contentTextViewFrame.size.height = contentTextViewFrame.size.height + contentHeightDiff;
    linkTextViewFrame.size.height = linkTextViewFrame.size.height + linkHeightDiff;
    
    self.linkTextView.frame = linkTextViewFrame;
    self.contentTextView.frame = contentTextViewFrame;
    
    [self updateCountLabel];
}

-(void)setupWithBranch:(id)branch{
    if (branch != nil && ![branch[@"key"] isEqualToString:self.currentBranch[@"key"]]) {
        self.currentBranch = [branch mutableCopy];
    }
}

-(void)setupWithTree:(Tree *)tree{
    self.linkTextView.placeholder = tree.data[@"link_prompt"];
    self.linkTextView.userInteractionEnabled = !tree.linkModeratorOnly || tree.isModerator;
    self.linkMax = self.linkTextView.userInteractionEnabled ? tree.linkMax : 0;
    
    self.contentTextView.placeholder = tree.data[@"content_prompt"];
    self.contentTextView.userInteractionEnabled = !tree.contentModeratorOnly || tree.isModerator;
    self.contentMax = self.contentTextView.userInteractionEnabled ? tree.contentMax : 0;
}

-(void)willMoveToWindow:(UIWindow *)newWindow{
    [super willMoveToWindow:newWindow];
    if (newWindow != nil) {
        [self setNeedsLayout];
    }
}

-(void)prepareForReuse{
    [super prepareForReuse];
    self.currentBranch = [@{@"link":@"",@"content":@""} mutableCopy];
    self.linkTextView.text = @"";
    self.contentTextView.text = @"";
}

-(void)awakeFromNib{
    [super awakeFromNib];
    self.currentBranch = [@{@"link":@"",@"content":@""} mutableCopy];
    self.linkTextView.placeholder = @"Add a teaser...";
    self.contentTextView.placeholder = @"...and continue with some more text";
}

- (void)textViewDidChange:(UITextView *)textView{
    
    CGFloat linkHeightDiff = 0.0;
    if (![self.linkTextView.text isEqualToString:@""]) {
        linkHeightDiff = self.linkTextView.contentSize.height - self.linkTextView.frame.size.height;
    }
    
    CGFloat contentHeightDiff = 0.0;
    if (![self.contentTextView.text isEqualToString:@""]) {
        contentHeightDiff = self.contentTextView.contentSize.height - self.contentTextView.frame.size.height;
    }
    
    if (0 != contentHeightDiff || 0 != linkHeightDiff) {
        [[NSNotificationCenter defaultCenter] postNotificationName:BranchFormTableViewCellUpdateSizeNotification object:self];
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if( [text isEqualToString:@"\t"] ){
        if ([textView isEqual:self.linkTextView]) {
            [self.contentTextView becomeFirstResponder];
        }else if ([textView isEqual:self.contentTextView]) {
            [self.linkTextView becomeFirstResponder];
        }
        return NO;
    }else if ([textView isEqual:self.linkTextView]) {
        self.currentBranch[@"link"] = [textView.text stringByReplacingCharactersInRange:range withString:text];
    }else if ([textView isEqual:self.contentTextView]) {
        self.currentBranch[@"content"] = [textView.text stringByReplacingCharactersInRange:range withString:text];
    }
    [self updateCountLabel];
    return YES;
}

#define HasValidCount(count) (count >= 0)
#define ColorForCount(count) (HasValidCount(count) ? [UIColor blackColor] : [UIColor redColor])

-(void)updateCountLabel{
    
    NSInteger contentRemaining = self.contentMax - [self.currentBranch[@"content"] length];
    NSInteger linkRemaining = self.linkMax - [self.currentBranch[@"link"] length];
    
    self.linkTextView.textColor = ColorForCount(linkRemaining);
    self.contentTextView.textColor = ColorForCount(contentRemaining);
    
    self.countLabel.text = [NSString stringWithFormat:@"link: %ld  content: %ld ",(long)linkRemaining,(long)contentRemaining];
    
}

@end
