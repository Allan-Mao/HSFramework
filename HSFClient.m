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

@end

@implementation HSFClient

-(NSMutableArray*)catchers
{
    if (!_catchers)_catchers = [[NSMutableArray alloc] init];
    return _catchers;
}

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

-(void)catcherFinished:(HSFCatcher*)catcher
{
    @synchronized(self) {
        if (![self.catchers containsObject:catcher])
            [NSException raise:NSInvalidArgumentException format:@"The catcher is not known."];
        [self.catchers removeObject:catcher];
    }
}

#pragma mark Class Methods

+(void)initialize
{
    _sharedHSFClient = [[HSFClient alloc] init];
    [HSFCatcher setHandler:_sharedHSFClient];
}

+(id)sharedHSFClient
{
    return _sharedHSFClient;
}

@end
