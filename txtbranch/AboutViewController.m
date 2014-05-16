//
//  AboutViewController.m
//  txtbranch
//
//  Created by Daniel Mueller on 5/14/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "AboutViewController.h"
#import <MessageUI/MFMailComposeViewController.h>

enum{
    EmailTag = 1,
};

@interface AboutViewController()<MFMailComposeViewControllerDelegate>

@end

@implementation AboutViewController

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 1) {
        
        NSURL* URL = [NSURL URLWithString:cell.detailTextLabel.text];
        
        if (URL) {
            [[UIApplication sharedApplication] openURL:URL];
        }
        
    }else{
        switch (cell.tag) {
            case EmailTag:{
                MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                controller.mailComposeDelegate = self;
                [controller setSubject:@"txtbranch iphone feedback"];
                [controller setToRecipients:@[@"feedback@gabicoware.com"]];
                [controller setMessageBody:@"Dear Gabicoware,\nYour app is" isHTML:NO];
                [self presentViewController:controller animated:YES completion:NULL];
            }
                break;
                
            default:
                break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
