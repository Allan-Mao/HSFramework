//
//  HSFAction.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 18/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFAction.h"
#import "HSFCommon.h"
#import "HSFExceptions.h"

@interface HSFAction(){
    // _request is an actual, important NSURLRequest.
    NSMutableURLRequest *_request;
}
@end

@implementation HSFAction

#pragma mark Properties

-(BOOL)networkActivityIndicator
{
    return YES;
}

-(NSTimeInterval)timeout
{
    return DEFAULT_CONNECTION_TIMEOUT;
}

-(NSDictionary*)HTTPHeaderFields
{
    [NSException raise:HSFAbstractNotOverridden format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return @{};
}


-(NSString*)attributesForSOAPActionTag
{
    // Default value. Is meant to be customized in a subclass.
    return @"";
}

-(NSString*)SOAPAction
{
    [NSException raise:HSFAbstractNotOverridden format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return @"";
}

-(NSString*)SOAPEnvelopeHead
{
    [NSException raise:HSFAbstractNotOverridden format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return @"";
}

-(NSString*)SOAPEnvelopeTail
{
    [NSException raise:HSFAbstractNotOverridden format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return @"";
}

-(NSDictionary*)SOAPParameters
{
    [NSException raise:HSFAbstractNotOverridden format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return @{};
}

-(NSArray*)SOAPParameterOrder
{
    return @[];
}

-(NSString*)HTTPBody
{
    return [[NSString alloc] initWithData:[self.request HTTPBody] encoding:NSUTF8StringEncoding];
}

-(BOOL)isParseUnitsAsynchronously
{
    return NO;
}

-(NSArray*)unitTags
{
    if (!_unitTags)_unitTags = @[];
    return _unitTags;
}

-(NSArray*)streamingTags
{
    if (!_streamingTags)_streamingTags = @[];
    return _streamingTags;
}

-(NSArray*)orderedSpecialTags
{
    if (!_orderedSpecialTags)_orderedSpecialTags = @[];
    return _orderedSpecialTags;
}

/*
 You had better not rely on this property in method implementations, use _request instead.
 */
-(NSURLRequest*)request
{
    [self updateSOAPBody];
    [self updateSOAPHeader];
    return [_request copy];
}

#pragma mark Public Methods

-(id)initWithURL:(NSURL *)url
{
    if (!url){
        [NSException raise:NSInvalidArgumentException format:@"url or SOAPAction is nil or empty."];
    }
    if ([self isMemberOfClass:NSClassFromString(HSF_ACTION_CLASS_NAME)]){
        [NSException raise:HSFAbstractNotOverridden format:@"You must subclass %@",HSF_ACTION_CLASS_NAME];
    }
    
    self = [super init];
    if (self) {
        // _request is a private instance variable.
        _request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.timeout];
        _url = url;
        [_request setHTTPMethod:POST_METHOD];
        
    }
    return self;
}

-(id)init
{
    [NSException raise:NSInternalInconsistencyException format:@"Use designated initializer."];
    return [super init];
}

/*
 Override the inherited method.
 */
-(NSString*)description
{
    //Getting URL
    NSString *url = [[NSString alloc] initWithFormat:@"%@\n",[self.url absoluteString]];
    
    //Getting HTTP Method
    NSString *httpMethod = [NSString stringWithFormat:@"METHOD: %@\n",[self.request HTTPMethod]];
    
    //Getting HTTP header
    NSString *httpHeader = [NSString stringWithFormat:@"HEADER:\n%@\n",[self.request allHTTPHeaderFields]];
    
    //Getting HTTP body
    NSString *body = [NSString stringWithFormat:@"BODY:\n%@",[[NSString alloc] initWithData:[self.request HTTPBody] encoding:NSUTF8StringEncoding]];
    
    //Print signature
    NSString *signature = [url stringByAppendingString:[httpMethod stringByAppendingString:[httpHeader stringByAppendingString:body]]];
    
    return signature;
}

-(NSURLCredential*)credential
{
    return nil;
}

#pragma mark Private Methods

/*
 Make xml SOAP document from parameters dictionary.
 Depends on a bunch of public methods that are meant to be customize at subclassing.
 */
-(NSString*)xmlForParameters:(NSDictionary*)parameters order:(NSArray*)order
{
    //TODO: refactor this code by using libXML2 with defines.
    
    NSMutableString *body;
    NSString *SOAPTag = [[NSString alloc] initWithFormat:@"%@ %@",self.SOAPAction,self.attributesForSOAPActionTag];
    SOAPTag = [SOAPTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([parameters count] > 0){
        body = [NSMutableString stringWithFormat:@"<%@>", SOAPTag];
        //We assume that parameter order does not matter.
        NSArray *keyOrder = (order.count)?order:[parameters allKeys];
        for (id key in keyOrder) {
            id value = parameters[key];
            if (![value isKindOfClass:[NSNull class]]){
                [body appendFormat:@"<%@>%@</%@>", key, value, key];
            } else {
                if (self.nilAttribute.length) {
                    [body appendFormat:@"<%@ %@/>",key,self.nilAttribute];
                } else {
                    [body appendFormat:@"<%@ />",key];
                }
            }
        }
        [body appendString:[NSString stringWithFormat:@"</%@>", self.SOAPAction]];
    } else {
        body = [NSMutableString stringWithFormat:@"<%@ />", SOAPTag];
    }
    
    NSString *xml = [[NSString alloc] initWithFormat:@"%@%@%@",self.SOAPEnvelopeHead,body,self.SOAPEnvelopeTail];
    
    // Check xml for valid xml document.
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[xml dataUsingEncoding:NSUTF8StringEncoding]];
    [parser parse];
    if ([parser parserError]){
#ifdef DEBUG
        NSLog(@"[%@ %@] EXCEPTION underlying XML: %@",[self class],NSStringFromSelector(_cmd),xml);
        [NSException raise:HSFInvalidXMLException format:@"XML document underlying HSFAction is not valid."];
#endif
    }
    
    return xml;
}

/*
 Update HTTP body for soap request from string into NSData and
 update "Content-Length" in request header
 */
-(void)updateSOAPBody
{
    NSString *body = [self xmlForParameters:self.SOAPParameters order:self.SOAPParameterOrder];
    [_request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
}

/*
 Update SOAP header based on public HTTPHeader property.
 Relies on private _request.
 */
-(void)updateSOAPHeader
{
    NSMutableDictionary *fields = [NSMutableDictionary dictionaryWithDictionary:self.HTTPHeaderFields];
    if (self.HTTPHeaderFields[CONTENT_LENGTH]){
        fields[CONTENT_LENGTH] = [NSString stringWithFormat:@"%lu",(unsigned long)[[_request HTTPBody] length]];
    }
    [_request setAllHTTPHeaderFields:[fields copy]];
}

@end