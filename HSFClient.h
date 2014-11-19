//
//  HSFClient.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 23/04/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSFAction.h"
#import "HSFCatcher.h"

@protocol HSFClientDelegate;

/*!
 @abstract Handmade SOAP Framework client singleton.
 @discussion A shared instance of this class initiate all network activity of HSFramework. It is a composite aggregation (UML not pattern) for HSFCatchers objects which responsible for receiving and handling raw information for a web service. This is also could be considered as a facade for whole HSFramework.
 */
@interface HSFClient : NSObject <HSFCatcherHandler>

/*!
 @abstract HSFClient delegate (weak pointer).
 */
@property (weak,nonatomic) id <HSFClientDelegate> delegate;

/*!
 @abstract Count of active HSFCatcher instances.
 */
@property (nonatomic,readonly) NSUInteger count;

/*!
 @abstract Perform SOAP action on a server, and handle response asynchronously.
 @discussion This methods creates new HSFCatcher and performs SOAP action.
 @param action HSFAction to perform.
 @param delegate HSFCatcherDelegate which will receive callbacks about processing request.
 @return HSFCatcher which were assigned to handle network job for this action.
 */
-(HSFCatcher*)loadAsynchronouslyWithAction:(HSFAction*)action delegate:(id<HSFCatcherDelegate>)delegate;

/*!
 @abstract Load data from server synchronously.
 @discussion This is just a wrapper for HSFCatcher analogous method. TODO: may shift it from HSFCatcher to here?
 */
-(HSFNode*)loadSynchronouslyWithAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error;

/*!
 @abstract Notification of catcher about finished job handler.
 */
-(void)catcherFinished:(HSFCatcher*)catcher;

/*!
 @abstract Shared instance of this singleton class.
 */
+(instancetype)sharedHSFClient;

@end

/*!
 @abstract HSFClient delegate.
 @discussion HSFClient will notify client about networking.
 */
@protocol HSFClientDelegate <NSObject>

/*!
 @abstract Send when network activity indicating should begin.
 */
-(void)didStartNetworkIndicating;

/*!
 @abstract Send when network activity indicating should stop.
 */
-(void)didStopNetworkIndicating;

@end
