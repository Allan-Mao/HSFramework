//
//  HSFClient.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 23/04/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFClient.h"
#import "HSFCommon.h"

static HSFClient *_sharedHSFClient;

@interface HSFClient()

@property (strong,nonatomic) NSMutableArray* catchers;
@property (nonatomic) NSUInteger networkActivities;

@end

@implementation HSFClient

#pragma mark Properties

-(NSMutableArray*)catchers
{
    if (!_catchers)_catchers = [[NSMutableArray alloc] init];
    return _catchers;
}

-(NSUInteger)count
{
    return [self.catchers count];
}

-(void)setNetworkActivities:(NSUInteger)networkActivities
{
    // Was non zero, becomes zero.
    if (networkActivities == 0 && _networkActivities !=0)
        [self.delegate didStopNetworkIndicating];
        
    // Was zero, becomes non zero.
    if (networkActivities !=0 && _networkActivities == 0)
        [self.delegate didStartNetworkIndicating];
        
    _networkActivities = networkActivities;
}

#pragma mark Tasks

-(HSFCatcher*)loadAsynchronouslyWithAction:(HSFAction*)action delegate:(id<HSFCatcherDelegate>)delegate
{
    if (!delegate || !action){
        [NSException raise:NSInvalidArgumentException format:@"The delegate or action is not set."];
    }
    @synchronized(self){
        HSFCatcher *catcher = [self supplyCatcherWithDelegate:delegate];
        [catcher loadAsynchronouslyWithAction:action];
        return catcher;
    }
}

-(HSFNode*)loadSynchronouslyWithAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error
{
    return [HSFCatcher loadSynchronouslyWithAction:action response:response error:error];
}

#pragma mark Private Methods

-(HSFCatcher*)supplyCatcherWithDelegate:(id<HSFCatcherDelegate>)delegate
{
    @synchronized(self){
        if (!delegate){
            [NSException raise:NSInvalidArgumentException format:@"The delegate is not set."];
        }
        
        HSFCatcher * catcher = [[HSFCatcher alloc] initWithDelegate:delegate];
        [self.catchers addObject:catcher];
       
        return catcher;
    }
}

#pragma mark HSFCatcherHandler protocol

-(void)catcherStarted:(HSFCatcher *)catcher
{
    @synchronized(self) {
        if (![self.catchers containsObject:catcher])
            [self.catchers addObject:catcher];
        
        if (catcher.actionStamp.networkActivityIndicator)
            self.networkActivities++;
    }
    
}

-(void)catcherFinished:(HSFCatcher*)catcher
{
    @synchronized(self) {
        if (![self.catchers containsObject:catcher]){
            return;
        }
        [self.catchers removeObject:catcher];
        
        if (catcher.actionStamp.networkActivityIndicator)
            self.networkActivities--;
    }
}

#pragma mark Class Methods

+(void)initialize
{
    _sharedHSFClient = [[HSFClient alloc] init];
    [HSFCatcher setHandler:_sharedHSFClient];
}

+(instancetype)sharedHSFClient
{
    return _sharedHSFClient;
}

@end
