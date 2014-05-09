//
//  TreeFormViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/28/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "TreeFormViewController.h"
#import "NSURL+txtbranch.h"

@interface TreeFormViewController ()<UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView* webView;
@property (nonatomic, strong) NSURL* URL;

@end

@implementation TreeFormViewController

-(IBAction)didTapCancelButton:(id)sender{
    [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString* path = nil;
    
    NSString* treeName = self.query[@"tree_name"];
    
    if (treeName) {
        path = [NSString stringWithFormat:@"/tree/%@/edit?hidechrome=1",treeName];
    }else{
        path = @"/tree/new?hidechrome=1";
    }
    self.URL = [NSURL tbURLWithPath:path];
    [self.webView loadRequest:[NSURLRequest requestWithURL: self.URL]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if ( [request.URL isEqual:self.URL] ) {
        return YES;
    }else{
        
        NSArray* components = [request.URL.path pathComponents];
        
        if (components.count == 3 && [components[1] isEqualToString:@"tree"] && ![components[2] isEqualToString:@"new"]) {
            
            if (![self.query[@"tree_name"] isEqualToString:components[2]]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"OpenTree" object:components[2] userInfo:nil];
            }else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateTree" object:components[2] userInfo:nil];
            }
            [self dismissViewControllerAnimated:YES completion:NULL];
            
        }
        
        return NO;
    }
}

@end
