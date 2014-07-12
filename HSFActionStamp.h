//
//  HSFActionStamp.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 07/05/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSFAction.h"

/*!
 @abstract HSFAction stamp (data copy).
 @discussion The responsibility of this class is to hold or fix action state.
 */
@interface HSFActionStamp : NSObject

//TODO: group headerDoc comment.
//Here should be only readonly properties.
@property (strong,nonatomic,readonly) NSURLRequest *request;
@property (strong,nonatomic,readonly) NSURLCredential *credential;
@property (nonatomic,readonly) NSUInteger loadAttempts;
@property (nonatomic,readonly) NSTimeInterval maxTimeout;
@property (nonatomic,readonly) BOOL networkActivityIndicator;
@property (strong,nonatomic,readonly) NSArray *unitTags;
@property (strong,nonatomic,readonly) NSArray *streamingTags;
@property (strong,nonatomic,readonly) NSArray *orderedSpecialTags;
@property (nonatomic,getter=isParseUnitsAsynchronously,readonly) BOOL parseUnitsAsynchronously;

/*!
 @abstract Class of the HSFAction from which stamp was made.
 */
@property (nonatomic,readonly) Class actionClass;

/*!
 @abstract Designated initializer.
 */
-(id)initWithAction:(HSFAction*)action;

@end
