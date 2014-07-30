//
//  Messages.h
//  txtbranch
//
//  Created by Daniel Mueller on 5/6/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "DataAsset.h"

@interface Messages : DataAsset

+(instancetype)currentMessages;

-(NSString*)errorMessageForResult:(id)result;

//static messages
-(NSString*)requestFailureMessage;

-(NSString*)resetLoginTitle;

-(NSString*)resetLoginMessage;

@end
