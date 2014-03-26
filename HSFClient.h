//
//  HSFClient.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 18/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HSFAction.h"
#import "HSFNode.h"

@protocol HSFClientDelegate;

/*!
 @abstract HSF SOAP client.
 @discussion An instance of this class sends a SOAP message and handles response. It uses delegate pattern to dispatch received NSFNode tree structures in asynchronous mode. It also has interface for synchronous loading. Note: the moment you activated one the async loading routine, the request is copied from HSFAction of fixedRequest and will be used subsequently. If you want to send another request, instantiate a new HSFClient. HSFClient performs all necessary network stuff. It is designed to be pretty much like NSURLConnection + a bunch of goodies.
 */
@interface HSFClient : NSObject <NSURLConnectionDataDelegate>

/*!
 @abstract Fixed NSURLRequest.
 @discussion This request is fixed just before downloading happen. It fixed in order to protect the request for changing while downloading.
 */
@property (strong,nonatomic,readonly) NSURLRequest *fixedRequest;

/*!
 @abstract Determine wether a client is performing asynchronous parsing.
 @discussion If parseUnitsAsynchronously set to YES, then this BOOL value determine whether if it is in parsing process or finished.
 */
@property (nonatomic,readonly) BOOL isParsing;

/*!
 @abstract Is process of loading on the go.
 @discussion This flag is set to YES just after async loading has been started, and set to NO after loading is finished or failed with error.
 */
@property (nonatomic, readonly) BOOL isInLoading;

/*!
 @abstract Determine wether parse specialized units asynchronously.
 @discussion YES if you need parse units asynchronously. Default value NO. Note if set this property to YES, then delegate callback methods will be sent NOT from the main thread but from PARSE_QUEUE thread.
 */
@property (nonatomic,getter=isParseUnitsAsynchronously) BOOL parseUnitsAsynchronously;

/*!
 @abstract Tags that represent units.
 @discussion As soon as client receive one of these tags it parses it an send to delegate.
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
 @discussion This object is created by HSFClient, it is a readonly property. Using this API you can cancel downloading.
 */
@property (strong,nonatomic,readonly) NSURLConnection *connection;

/*!
 @abstract Underlying HSFAction
 @discussion HSFAction and its subclasses which will be used for networking. It is readonly property, if you need another HSFAction then instantiate new HSFClient.
 */
@property (strong,nonatomic,readonly) HSFAction *action;

/*!
 @abstract HSFClient delegate
 @discussion It conforms HSFClientDelegate protocol.
 */
@property (strong,nonatomic) id <HSFClientDelegate> delegate;

#pragma mark Tasks

/*!
 @abstract Username for authentication challenge.
 @discussion This getter is for a class variable. Could be customized in a subclass.
 */
+(NSString*)username;

/*!
 @abstract Set username for authentication challenge.
 @discussion Class variable setter.
 */
+(void)setUsername:(NSString*)username;

/*!
 @abstract Password for authentication challenge.
 @discussion This getter is for a class variable. Could be customized in a subclass.
 */
+(NSString*)password;

/*!
 @abstract Password for authentication challenge.
 @discussion Class variable setter.
 */
+(void)setPassword:(NSString*)password;


/*!
 @abstract Load data from server synchronously.
 @discussion This method sends a request to a server (based on given HSFAction) and returns a result in the form of HSFNode tree. Note: this is class method that's why no authentication challenge callback.
 @param response Out parameter for the URL response returned by the server.
 @param error Out parameter used if an error occurs while processing the request. May be NULL.
 */
+(HSFNode*)loadSynchronouslyAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error;

/*!
 @abstract Load data from server asynchronously using callbacks.
 @discussion This method sends a request to a server (based on underlying HSFAction) and initiates asynchronous process of receiving and handling a response. Do not send messages to a delegate which it does not implement.
 */
-(void)loadAsynchronously;

/*!
 @abstract Convenience initializer.
 @discussion Initializes a HSF client and sets action for it. Start loading immediately i.e. startImmediately parameter for designated initializer set to YES.
 @param action Underpinning HSFAction or its subclass.
 @param delegate The delegate object to respond to callbacks.
 @return Initialized HSF client performing asynchronous loading.
 */
-(id)initWithAction:(HSFAction*)action delegate:(id <HSFClientDelegate>)delegate;

/*!
 @abstract Designated initializer.
 @discussion Initializes a HSF client and sets action delegate for it.  Throws an exception if delegate is not set properly.
 @param action Underpinning HSFAction or its subclass.
 @param delegate The delegate object to respond to callbacks.
 @param startImmediately Determine wether to start loading immediately.
 @return Initialized HSF client.
 */
-(id)initWithAction:(HSFAction *)action delegate:(id <HSFClientDelegate>)delegate startImmediately:(BOOL)startImmediately;

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

@end

/*!
 @abstract Protocol for delegate of HSFClient.
 @discussion Protocol to define HSFClient delegate, which will asynchronously receive specialized units or entire response.
 */
@protocol HSFClientDelegate <NSObject>

@optional
/*!
 @abstract Handle received specialized unit.
 @discussion Specialized units are XML structures denoting units.
 @param client HSFClient which handled connection.
 @param rootNode Root node corresponding to newly available XML tree structure of unit.
 */
-(void)client:(HSFClient*)client didReceiveUnit:(HSFNode*)rootNode;

/*!
 @abstract Handle entire response asynchronously.
 @discussion This task handles an entire XML tree received from server.
 @param client HSFClient which handled a connection.
 @param rootNode Root node of entire response XML tree structure.
 */
-(void)client:(HSFClient*)client didReceiveEntireResponse:(HSFNode*)rootNode;

/*!
 @abstract Handle async loading error.
 @discussion This task is called if async loading failed after all necessary attempts.
 @param client HSFClient which handled a connection.
 @param error An error object containing details of the fail.
 */
-(void)client:(HSFClient*)client didFailLoadingWithError:(NSError*)error;

/*!
 @abstract Handle authentication challenge error.
 @discussion This task is called if authentication  challenge is failed.
 @param client HSFClient which handled a connection.
 @param error An error object containing details of the fail.
 */
-(void)client:(HSFClient*)client didFailAuthenticationWithError:(NSError*)error;

@end
