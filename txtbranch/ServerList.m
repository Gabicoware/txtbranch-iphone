//
//  ServerList.m
//  txtbranch
//
//  Created by Daniel Mueller on 4/25/14.
//  Copyright (c) 2014 Gabicoware. All rights reserved.
//

#import "ServerList.h"
#import "NSURL+txtbranch.h"

#if LOCAL
#define DEFAULT_SERVER @{@"address":@"http://localhost:8080/",@"name":@"localhost"}
#else
#define DEFAULT_SERVER @{@"address":@"http://txtbranch.gabicoware.com/",@"name":@"txtbranch"}
#endif

NSString* ServerListFileLocation();

NSString* ServerListFileLocation(){
    NSString* documentspath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/servers.dat", documentspath];
}

@implementation ServerList{
    NSMutableSet* _servers;
    NSDictionary* _activeServer;
}

+(instancetype)instance{
    static ServerList* _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [ServerList new];
    });
    return _instance;
}

-(instancetype)init{
    if((self = [super init])){
        NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:ServerListFileLocation()];
        _activeServer = dict[@"activeServer"];
        if ([dict[@"servers"] count] < 1) {
            _servers = [[NSMutableSet alloc] initWithArray:@[[self activeServer]]];
        }else{
            _servers = [[NSMutableSet alloc] initWithArray:dict[@"servers"]];
        }
    }
    return self;
}

-(NSDictionary*)activeServer{
    if (_activeServer == nil) {
        return DEFAULT_SERVER;
    }
    return _activeServer;
}

-(void)setActiveServer:(NSDictionary*)server{
    if (![server isEqual:_activeServer] && [_servers containsObject:server]) {
        _activeServer = server;
        [self synchronize];
    }
}

-(NSArray*)servers{
    return [_servers allObjects];
}

-(void)addServer:(NSString *)server{
    [_servers addObject:server];
    [self synchronize];
}

-(void)removeServer:(NSString *)server{
    [_servers removeObject:server];
    [self synchronize];
}

-(void)synchronize{
    [@{@"activeServer":self.activeServer,@"servers":self.servers} writeToFile:ServerListFileLocation() atomically:YES];
}

@end
