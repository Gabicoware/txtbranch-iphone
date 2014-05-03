//
//  ServerList.h
//  txtbranch
//
//  Created by Daniel Mueller on 4/25/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerList : NSObject

-(void)removeServer:(NSDictionary*)server;
-(void)addServer:(NSDictionary*)server;

//setting the active server to one that is not in the servers list has no effect
@property (nonatomic, strong) NSDictionary* activeServer;

@property (nonatomic, readonly) NSArray* servers;

+(instancetype)instance;

@end
