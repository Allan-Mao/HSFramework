//
//  HSFCatcher.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 18/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSFAction.h"
#import "HSFNode.h"
#import "HSFNode+NSXMLParserDelegate.h"

@protocol HSFCatcherDelegate;
@protocol HSFCatcherHandler;

/*!
 @abstract HSF SOAP catcher.
 @discussion An instance of this class sends a SOAP message and handles response. It uses delegate pattern to dispatch received NSFNode tree structures in asynchronous mode. It also has interface for synchronous loading. Note: the moment you activated the async loading routine, the request is copied from HSFAction to fixedRequest and will be used subsequently. HSFCatcher performs all necessary network stuff.
 */
@interface HSFCatcher : NSObject <NSURLConnectionDataDelegate,HSFNodeParseErrorHandler>

/*!
 @abstract Fixed NSURLRequest.
 @discussion This request is fixed just before downloading happen. It fixed in order to protect the request for changing while downloading.
 */
@property (strong,nonatomic,readonly) NSURLRequest *fixedRequest;

/*!
 @abstract Determine wether a catcher is performing asynchronous parsing.
 @discussion If parseUnitsAsynchronously set to YES, then this BOOL value determine whether if it is in parsing process or finished.
 */
@property (nonatomic,readonly) BOOL isParsing;

/*!
 @abstract Is process of loading on the go.
 @discussion This flag is set to YES just after async loading has been started, and set to NO after loading is finished or failed with error.
 */
@property (nonatomic,readonly) BOOL isInLoading;

/*!
 @abstract Determine wether parse specialized units asynchronously.
 @discussion YES if you need parse units asynchronously. Default value NO. Note if set this property to YES, then delegate callback methods will be sent NOT from the main thread but from PARSE_QUEUE thread. I.e in this case you need to dispatch async to the main queue in the body of your delegate methods of HSFCatcherDelegate.
 */
@property (nonatomic,getter=isParseUnitsAsynchronously) BOOL parseUnitsAsynchronously;

/*!
 @abstract Tags that represent units.
 @discussion As soon as catcher receive one of these tags it parses it an send to delegate.
 */
@property (strong,nonatomic) NSArray* unitTags;

/*!
 @abstract Unit recognized.
 @discussion This represents number of extracted unit in xml format.
 */
@property (nonatomic,readonly) NSUInteger unitRecognized;

/*!
 @abstract Unit processed.
 @discussion Unit parsed and sent to delegate.
 */
@property (nonatomic,readonly) NSUInteger unitProcessed;

/*!
 @abstract Connection object that loads content.
 @discussion This object is created by HSFCatcher, it is a readonly property. Using this API you can cancel downloading.
 */
@property (strong,nonatomic,readonly) NSURLConnection *connection;

/*!
 @abstract HSFCatcher delegate
 @discussion It conforms HSFCatcherDelegate protocol.
 */
@property (strong,nonatomic) id <HSFCatcherDelegate> delegate;

#pragma mark Tasks

/*!
 @abstract Load data from server synchronously.
 @discussion This method sends a request to a server (based on given HSFAction) and returns a result in the form of HSFNode tree. Note: this is class method that's why no authentication challenge callback.
 @param response Out parameter for the URL response returned by the server.
 @param error Out parameter used if an error occurs while processing the request. May be NULL.
 */
+(HSFNode*)loadSynchronouslyWithAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error;

/*!
 @abstract Load data from server asynchronously using callbacks.
 @discussion This method sends a request to a server (based on given HSFAction) and initiates asynchronous process of receiving and handling a response.
 @param action HSFAction which will be used for request generation.
 */
-(void)loadAsynchronouslyWithAction:(HSFAction*)action;

/*!
 @abstract Repeat loading.
 @discussion Cather repeats asynchronous loading with the request it used at last load.
 */
-(void)reloadAsynchronously;

/*!
 @abstract Designated initializer.
 @discussion Initializes a HSFCatcher and sets delegate for it. Throws an exception if delegate is not set.
 @param delegate The delegate object to respond to callbacks.
 @return Initialized HSFCatcher.
 */
-(id)initWithDelegate:(id <HSFCatcherDelegate>)delegate;

#pragma mark NSURLConnectionDataDelegate Methods

/*!
 @abstract Response received asynchronously.
 @discussion This task should reset received data storage for a new download and all statistics properties (e.g unitProcessed)
 @param connection The connection sending the message.
 @param response Received response from the server.
 */
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
//TODO: Think about responses with errors e.g. 400.

/*!
 @abstract Handle arbitrary piece of downloaded data.
 @discussion This task extracts XML structures with unitTags as root tags the moment it downloads them. Then it parses them and dispatches to delegate using client:didReceiveUnit:. Parsing happens synchronously or asynchronously depending on parseUnitsAsynchronously property. It also collect the data to handle entire response.
 @param connection The connection sending the message.
 @param data The newly available data.
 */
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;

/*!
 @abstract Handle finish of the loading process.
 @discussion This task handles data which was collected by didReceiveData method, parses it and dispatches it delegate using client:didReceiveEntireResponse:.
 @param connection The connection sending the message.
 */
-(void)connectionDidFinishLoading:(NSURLConnection *)connection;

/*!
 @abstract Loading error handler.
 @discussion This tasks sets connection to nil and repeats loading after timeout. The timeout is gradually increased until MAX_TIMEOUT, then connection is closed.
 @param connection The connection sending the message.
 @param error An error object containing details of why the connection failed to load the request successfully.
 */
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

/*!
 @abstract Handle authentication challenge.
 @discussion This task is called when a request for an authentication challenge is sent.
 @param connection The connection sending the message.
 @param challenge The authentication challenge for which a request is being sent.
 */
-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

/*!
 @abstarct Returns aggregator.
 @discussion Throws an exception if handler is nil.
 */
+(id<HSFCatcherHandler>)handler;

/*!
 @abstract HSFCatcher aggregator setter.
 */
+(void)setHandler:(id<HSFCatcherHandler>)handler;

@end

/*!
 @abstract HSFCatcherHandler protocol.
 @discussion The object conforming this protocol and set as handler for HSFCatcher class will receive notification when a catcher finished loading job.
 */
@protocol HSFCatcherHandler <NSObject>

/*!
 @abstract Notification of catcher that has finished its job.
 */
-(void)catcherFinished:(HSFCatcher*)catcher;

@end

/*!
 @abstract Protocol for delegate of HSFCatcher.
 @discussion Protocol to define HSFCatcher delegate, which will asynchronously receive specialized units or entire response.
 */
@protocol HSFCatcherDelegate <NSObject>

@optional
/*!
 @abstract Handle received specialized unit.
 @discussion Specialized units are XML structures denoting units.
 @param catcher HSFCatcher which handled connection.
 @param rootNode Root node corresponding to newly available XML tree structure of unit.
 */
-(void)catcher:(HSFCatcher*)catcher didReceiveUnit:(HSFNode*)rootNode;

/*!
 @abstract Handle entire response asynchronously.
 @discussion This task handles an entire XML tree received from server.
 @param catcher HSFCatcher which handled a connection.
 @param rootNode Root node of entire response XML tree structure.
 */
-(void)catcher:(HSFCatcher*)catcher didReceiveEntireResponse:(HSFNode*)rootNode;

/*!
 @abstract Handle async loading error.
 @discussion This task is called if async loading failed after all necessary attempts.
 @param catcher HSFCatcher which handled a connection.
 @param error An error object containing details of the fail.
 */
-(void)catcher:(HSFCatcher*)catcher didFailLoadingWithError:(NSError*)error;

/*!
 @abstract Handle authentication challenge error.
 @discussion This task is called if authentication  challenge is failed.
 @param catcher HSFCatcher which handled a connection.
 @param error An error object containing details of the fail.
 */
-(void)catcher:(HSFCatcher*)catcher didFailAuthenticationWithError:(NSError*)error;

@end
