//
//  HSFActionStamp.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 07/05/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFActionStamp.h"

@interface HSFActionStamp()

//Here we make all readonly properties readwrite.
@property (strong,nonatomic,readwrite) NSURLRequest *request;
@property (strong,nonatomic,readwrite) NSURLCredential *credential;
@property (nonatomic,readwrite) NSUInteger loadAttempts;
@property (nonatomic,readwrite) NSTimeInterval maxTimeout;
@property (nonatomic,readwrite) BOOL networkActivityIndicator;
@property (strong,nonatomic,readwrite) NSArray* unitTags;
@property (strong,nonatomic,readwrite) NSArray* streamingTags;
@property (strong,nonatomic,readwrite) NSArray *orderedSpecialTags;
@property (nonatomic,getter=isParseUnitsAsynchronously,readwrite) BOOL parseUnitsAsynchronously;

@property (nonatomic,readwrite) Class actionClass;

@end;

@implementation HSFActionStamp

-(id)initWithAction:(HSFAction*)action;
{
    self = [super init];
    if (self) {
        self.actionClass = [action class];
        
        self.request = action.request;
        self.credential = action.credential;
        self.loadAttempts = action.loadAttempts;
        self.maxTimeout = action.maxTimeout;
        self.networkActivityIndicator = action.networkActivityIndicator;
        self.unitTags = action.unitTags;
        self.parseUnitsAsynchronously = action.isParseUnitsAsynchronously;
        self.streamingTags = action.streamingTags;
        self.orderedSpecialTags = action.orderedSpecialTags;
    }
    return self;
}

@end
