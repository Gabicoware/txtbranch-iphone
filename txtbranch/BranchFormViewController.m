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

@interface BranchFormViewController()

-(IBAction)didTapCancelButton:(id)sender;
-(IBAction)didTapSaveButton:(id)sender;

//TODO: consolidate these properties

@property (nonatomic,weak) IBOutlet TBTextView* linkTextView;
@property (nonatomic,weak) IBOutlet TBTextView* contentTextView;
@property (nonatomic,weak) IBOutlet UILabel* countLabel;

@property (nonatomic,readonly) NSString* branchKey;
@property (nonatomic,readonly) NSString* parentBranchKey;

@property (nonatomic,strong) NSDictionary* unsavedBranch;

@property (nonatomic,readonly) Tree* tree;
@property (nonatomic,strong) NSDictionary* branch;
@property (nonatomic,readonly) UIScrollView* scrollView;

@property (nonatomic,strong) NSMutableDictionary* currentBranch;
@property (nonatomic,assign) NSUInteger linkMax;
@property (nonatomic,assign) NSUInteger contentMax;


@end


@implementation BranchFormViewController{
    BOOL _needsConfirmation;
}
@synthesize query=_query;

-(UIScrollView*)scrollView{
    return (UIScrollView*)self.view;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setupNotifications];
    if (self.branchKey) {
        self.title = @"Edit Branch";
    }else{
        self.title = @"Add a Branch";
    }
    
    self.currentBranch = [@{@"link":@"",@"content":@""} mutableCopy];
    self.linkTextView.placeholder = @"Add a teaser...";
    self.contentTextView.placeholder = @"...and continue with some more text";
    [self setFields];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleApplicationWillTerminateNotification:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
}

-(void)handleApplicationWillTerminateNotification:(NSNotification*)notification{
    [self.tree addUnsavedBranch:[self branchData]
                       forQuery:self.query];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.linkTextView becomeFirstResponder];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    [self.linkTextView layoutSubviews];
    [self.contentTextView layoutSubviews];
    
    [self.linkTextView sizeToFit];
    [self.contentTextView sizeToFit];
    
    CGRect linkTextViewFrame = self.linkTextView.frame;
    CGRect contentTextViewFrame = self.contentTextView.frame;
    
    contentTextViewFrame.origin.y = linkTextViewFrame.origin.y + linkTextViewFrame.size.height;
    
    self.contentTextView.frame = contentTextViewFrame;
    
    CGRect countLabelFrame = self.countLabel.frame;
    
    countLabelFrame.origin.y = contentTextViewFrame.origin.y + contentTextViewFrame.size.height;
    
    self.countLabel.frame = countLabelFrame;
    
    [self updateCountLabel];
    
    CGSize contentSize = CGSizeZero;
    
    contentSize.width = self.scrollView.frame.size.width;
    contentSize.height = CGRectGetMaxY(countLabelFrame) + linkTextViewFrame.origin.y;
    
    self.scrollView.contentSize = contentSize;
}

-(void)setQuery:(NSDictionary *)query{
    _query = query;
    self.unsavedBranch = [self.tree getUnsavedBranchForQuery:self.query];
    [self.tree deleteUnsavedBranchForQuery:self.query];
    _needsConfirmation = self.unsavedBranch != nil;
    if (_needsConfirmation) {
        [[[UIAlertView alloc] initWithTitle:@"Restore Branch?"
                                    message:@"You have an unsaved branch. Would you like to use it? Otherwise it will be deleted."
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@[@"Yes"]
                                      block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                          if ( buttonIndex == 0 ) {
                                              self.unsavedBranch = nil;
                                          }
                                          _needsConfirmation = NO;
                                          [self setFields];
        }] show];
    }
    [self setFields];
}

-(void)setFields{
    if (!_needsConfirmation) {
        
        [self setupWithTree:self.tree];

        
        id branch = self.unsavedBranch;
        if (branch == nil && self.branchKey) {
            branch = self.tree.branches[self.branchKey];
        }
        if (branch) {
            self.contentTextView.text =branch[@"content"];
            self.linkTextView.text =branch[@"link"];
            [self setupWithBranch:branch];
        }
        
        [self.view setNeedsLayout];

        
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

-(void)setupNotifications{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardNotification:) name:UIKeyboardDidShowNotification object:nil];
}

-(IBAction)didTapCancelButton:(id)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(NSMutableDictionary*)branchData{
    NSMutableDictionary* branch = nil;
    
    if (self.branchKey != nil) {
        
        branch = [self.tree.branches[ self.branchKey ] mutableCopy];
        ((NSMutableDictionary*)branch)[@"content"] = self.contentTextView.text;
        ((NSMutableDictionary*)branch)[@"link"] = self.linkTextView.text;
        
    }else{
        branch = [@{@"link": self.linkTextView.text,
                    @"content":self.contentTextView.text,
                    @"parent_branch_key":self.parentBranchKey} mutableCopy];
    }
    return branch;
}

-(IBAction)didTapSaveButton:(id)sender{
    NSMutableDictionary* branch = [self branchData];
    
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
    if(self.linkTextView.isFirstResponder){
        [self centerTextView:self.linkTextView];
    }
    if (self.contentTextView.isFirstResponder) {
        [self centerTextView:self.contentTextView];
    }
    
    CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect convertedRect = [self.scrollView.superview convertRect:endFrame fromView:self.view.window];
    
    UIEdgeInsets insets = self.scrollView.contentInset;
    
    if (CGRectIntersectsRect(convertedRect, self.view.frame)) {
        CGRect intersection = CGRectIntersection(convertedRect, self.view.frame);
        insets.bottom = intersection.size.height;
        
    }else{
        insets.bottom = 0.0;
    }
    self.scrollView.contentInset = insets;
}

-(void)centerTextView:(UITextView*)textView{
    UITextRange * selectionRange = [textView selectedTextRange];
    CGRect selectionStartRect = [textView caretRectForPosition:selectionRange.start];
    CGRect selectionEndRect = [textView caretRectForPosition:selectionRange.end];
    CGPoint selectionCenterPoint = (CGPoint){(selectionStartRect.origin.x + selectionEndRect.origin.x)/2,(selectionStartRect.origin.y + selectionStartRect.size.height / 2)};
    
    CGPoint point = [self.scrollView convertPoint:selectionCenterPoint fromView:textView];
    
    
    if (!CGRectContainsPoint( CGRectInset( self.scrollView.bounds, 0, 30) , point )) {
        
        CGPoint offsetPoint = CGPointZero;
        offsetPoint.y = point.y - self.scrollView.bounds.size.height*0.66666;
        
        [self.scrollView setContentOffset:offsetPoint animated:YES];
    }
    
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
    [self updateCountLabel];
}

- (void)textViewDidChange:(UITextView *)textView{
    [self.view setNeedsLayout];
    [self updateCountLabel];
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
