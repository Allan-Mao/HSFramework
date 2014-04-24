//
//  HSFAction.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 18/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @abstract SOAP action with NSURLRequest as a derived property.
 @discussion In essence SOAP exchange represents special XML document sending through HTTP POST method. This class encapsulates SOAP envelope with NSURLRequest as a property. Request is constructed based on data in the envelope. We assume that this class will be subclassed for the concrete application with all necessary methods overridden to fulfil specific exchange. That's why this framework is not bound to soap1.2 or soap1.1. This is an abstract class, won't work without subclassing. This class for HSFCatcher is like a NSURLRequest for NSURLConnection.
 */
@interface HSFAction : NSObject

/*!
 @abstract Automatic reload attempts if some connection errors appeared.
 @discussion After this number of attempts automatic reload won't be taken anymore. If you want only only one attempt set 0 or 1.
 */
@property (nonatomic) NSUInteger loadAttempts;

/*!
 @abstract Automatic reload maximum timeout.
 @discussion Using this value and number of loadAttempts timeout step will be determined. After the expiration of this step new shot to connect will be taken.
 */
@property (nonatomic) NSTimeInterval maxTimeout;

/*!
 @abstract HTTP header fields.
 @discussion This getter is abstract must be customized in a subclass. Note: Content-Length will be derived from the request if presented.
 */
@property (strong,nonatomic,readonly) NSDictionary *HTTPHeaderFields;

/*!
 @abstract The text of attributes for SOAP action start tag.
 @discussion This is meant be customized in a subclass for additional xml attributes. If eventually the xml document won't be valid, an exception will be thrown. E.g. xmlns="httpL=://example.com". By default it is @"".
 */
@property (strong,nonatomic,readonly) NSString *attributesForSOAPActionTag;

/*!
 @abstract The beginning part of XML SOAP envelope.
 @discussion This property represents the head part of an xml document which constitutes SOAP envelope. It should contain all necessary tags up to  a tag representing SOAP Action. This is an abstract method and meant to be customized in a subclass. If eventually the xml document won't be valid, an exception will be thrown.
 */
@property (strong,nonatomic,readonly) NSString *SOAPEnvelopeHead;

/*!
 @abstract The ending part of XML SOAP envelope.
 @discussion This property represents the end part of an xml document which constitutes SOAP envelope. It should contain all necessary tags up to properly finish xml document. This is an abstract method meant to be customized in a subclass. If eventually the xml document won't be valid, an exception will be thrown.
 */
@property (strong,nonatomic,readonly) NSString *SOAPEnvelopeTail;

/*!
 @abstract The HTTP body text derived from the underlying NSURLRequest.
 @discussion Convenient way to look xml soap envelope which is going to be send.
 */
@property (strong,nonatomic,readonly) NSString* HTTPBody;

/*!
 @abstract The underlying NSURLRequest instance.
 @discussion This instance will contain SOAP envelope as HTTP body. The HTTP method is POST.
 */
@property (strong,nonatomic,readonly) NSURLRequest *request;

/*!
 @abstract The URL to a server.
 @discussion This NSURL instance was passed in initialization method.
 */
@property (strong,nonatomic,readonly) NSURL *url;

/*!
 @abstract The SOAP Action.
 @discussion The SOAP Action to use in a SOAP envelope. Readonly. Abstract, must be customized in a subclass.
 */
@property (strong,nonatomic,readonly) NSString *SOAPAction;

/*!
 @abstract Parameters for SOAP XML document.
 @discussion These parameters will be used in SOAP envelope e.g. @{@"key":@"value"} would become <key>value</key> in the XML document. Throws an exception if resulting XML document won't be valid. It is an abstract method and must to be customized in subclasses.
 @param parameters The NSDictionary of NSStrings.
 */
@property (strong,nonatomic,readonly) NSDictionary *SOAPParameters;

#pragma mark Tasks

/*!
 @abstract Designated initializer.
 @discussion Returns an initialized SOAP request with specified values.
 @param url The URL for the request. Must not be nil.
 @return The initialized SOAP request.
 */
-(id)initWithURL:(NSURL*)url;

/*!
 @abstract Credential for action.
 @discussion Is meant to be implemented in subclass.
 @return Credential which will be used by HSFCatcher for authentication challenge. Returns nil by default.
 */
-(NSURLCredential*)credential;

@end
