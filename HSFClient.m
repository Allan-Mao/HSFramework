//
//  HSFClient.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 18/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFClient.h"
#import "HSFAction.h"
#import "HSFCommon.h"
#import "HSFExceptions.h"
#import "HSFNode+NSXMLParserDelegate.h"

static NSString *_username = @"";
static NSString *_password = @"";

@interface HSFClient()

/*
 Temporary storage for received data
 */
@property (strong, nonatomic) NSMutableData *cumulativeData;

// Make writeable properties at private side.
@property (strong,nonatomic,readwrite) NSURLConnection *connection;
@property (nonatomic,readwrite) NSUInteger unitRecognized;
@property (nonatomic,readwrite) NSUInteger unitProcessed;
@property (strong,nonatomic,readwrite) NSURLRequest *fixedRequest;
@property (nonatomic,readwrite) BOOL isInLoading;

@property (nonatomic) NSInteger unitInProgress;
@property (strong,nonatomic) dispatch_queue_t parseQueue;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) NSUInteger reloadAttemptsMade;
@property (strong,nonatomic) NSString *fixedTag;
@property (strong,nonatomic) NSMutableString *bufferString;

@end

@implementation HSFClient

#pragma mark Properties

-(NSMutableString*)bufferString
{
    if(!_bufferString)_bufferString = [[NSMutableString alloc] init];
    return _bufferString;
}

-(dispatch_queue_t)parseQueue
{
    if(!_parseQueue)_parseQueue = dispatch_queue_create(PARSE_QUEUE, NULL);
    return _parseQueue;
}

-(BOOL)isParsing
{
    return (self.unitInProgress) ? NO : YES;
}

-(NSArray*)unitTags
{
    if(!_unitTags)_unitTags = @[];
    return _unitTags;
}

-(NSMutableData*)cumulativeData
{
    if (!_cumulativeData)_cumulativeData = [[NSMutableData alloc] init];
    return _cumulativeData;
}

#pragma mark Public Methods

+(NSString*)username
{
    //_username - global static variable
    return _username;
}

+(void)setUsername:(NSString *)username
{
    _username = username;
}

+(NSString*)password
{
    //_password - global static variable
    return _password;
}

+(void)setPassword:(NSString *)password
{
    _password = password;
}

+(HSFNode*)loadSynchronouslyAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error;
{
    NSData *data = [NSURLConnection sendSynchronousRequest:action.request returningResponse:response error:error];
    return [HSFNode nodeTreeFromData:data];
}

-(void)loadAsynchronously
{
    if (!self.delegate){
        [NSException raise:NSInvalidArgumentException format:@"The delegate is not set."];
    }
    // Fix request.
    if (!self.fixedRequest) self.fixedRequest = self.action.request;
    if (!self.isInLoading) self.isInLoading = YES;
    self.connection = [[NSURLConnection alloc] initWithRequest:self.fixedRequest delegate:self];
}

-(id)initWithAction:(HSFAction *)action delegate:(id <HSFClientDelegate>)delegate startImmediately:(BOOL)startImmediately;
{
    self = [super init];
    
    if (!action || !delegate){
        [NSException raise:NSInvalidArgumentException format:@"action is nil."];
    }
    
    if (self){
        _action = action;
        _delegate = delegate;
        _parseUnitsAsynchronously = NO;
        _isInLoading = NO;
        if (startImmediately){
            [self loadAsynchronously];
        }
    }
    
    return self;
}

-(id)initWithAction:(HSFAction*)action delegate:(id <HSFClientDelegate>)delegate;
{
    return [self initWithAction:action delegate:delegate startImmediately:YES];
}

-(id)init
{
    [NSException raise:NSInternalInconsistencyException format:@"Use designated initializer."];
    return [super init];
}

#pragma mark NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.cumulativeData setLength:0];
    self.unitInProgress = 0;
    self.unitRecognized = 0;
    self.unitProcessed = 0;
    self.timeout = 0.0;
    self.reloadAttemptsMade = 1;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([data length] == 0)
        [NSException raise:HSFServiceResponseException format:@"Server should not return empty data in SOAP exchange."];
    
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR)])
        [self.cumulativeData appendData:data];
    
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR)] && [self.unitTags count] > 0){
    
        NSString *stringToProcess;
        if (!self.bufferString) self.bufferString = [[NSMutableString alloc] init];
        [self.bufferString appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        
        NSRange range;
        BOOL isNeedNewData = NO;
        
        //Start process received string.
        while (!isNeedNewData){
            
            // Search if non of the tags is found.
            if ([self.fixedTag length] == 0){
                for (NSString *tag in self.unitTags){
                    NSString *openTag = [@"<" stringByAppendingString:tag];
                    range = [self.bufferString rangeOfString:openTag options:NSCaseInsensitiveSearch];
                    if (range.location != NSNotFound){
                        //Cutting buffer
                        [self.bufferString deleteCharactersInRange:NSMakeRange(0, range.location)];
                        self.fixedTag = tag;
                        break;
                    }
                }
            }
            
            // Check for standalone <tag/>
            if ([self.fixedTag length]>0 && [stringToProcess length] == 0){
                // range.location of substring which is not found is NSNotFound = NSIntegerMax.
                range = [self.bufferString rangeOfString:@"/>"];
                if (range.location != NSNotFound && range.location < [self.bufferString rangeOfString:@"<" options:NSLiteralSearch range:NSMakeRange(range.length, [self.bufferString length]-range.length)].location){
                    stringToProcess = [self.bufferString substringToIndex:(range.location+range.length)];
                    //Cutting Buffer
                    [self.bufferString setString:[self.bufferString substringFromIndex:(range.location+range.length)]];
                    self.fixedTag = nil;
                }
            }
            
            
            // Combining data for specified tag
            if ([self.fixedTag length]){
                NSString *closedTag = [NSString stringWithFormat:@"</%@>", self.fixedTag];
                range = [self.bufferString rangeOfString:closedTag options:NSCaseInsensitiveSearch];
                if (range.location != NSNotFound){
                    stringToProcess = [self.bufferString substringToIndex:(range.location+range.length)];
                    // Cut new string
                    [self.bufferString setString:[self.bufferString substringFromIndex:(range.location+range.length)]];
                    self.fixedTag = nil;
                } else {
                    // Closed Tag is not found
                    //New Load
                    isNeedNewData = YES;
                }
            } else if (![stringToProcess length]){
                //New Load
                isNeedNewData = YES;
            }
            
            if (![self.fixedTag length] && [stringToProcess length]){
                ++self.unitRecognized;
                NSData *dataToParse = [stringToProcess dataUsingEncoding:NSUTF8StringEncoding];
                
                [self performParseOperation:^{
                    HSFNode *root = [HSFNode nodeTreeFromData:dataToParse];
                    ++self.unitProcessed;
                    [self.delegate performSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR) withObject:self withObject:[root.children firstObject]];
                }];
                
                stringToProcess = @"";
            }
        }
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self.cumulativeData length] == 0)
        [NSException raise:HSFServiceResponseException format:@"No data received while loading."];
    
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR)]){
        HSFNode* root = [HSFNode nodeTreeFromData:self.cumulativeData];
        // root is pointer to tree root element
        [self.delegate performSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR) withObject:self withObject:[root.children firstObject]];
    }
    // Perform this text only in DEBUG mode.
#ifdef DEBUG
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR)] && [self.unitTags count] > 0){
        HSFNode* root = [HSFNode nodeTreeFromData:self.cumulativeData];
        NSUInteger total = 0;
        for (NSString *tag in self.unitTags){
            total += [root countOfNodesByName:tag];
        }
        if (self.unitProcessed != total){
            [NSException raise:HSFClientMissedElementException format:@"Number of elements counted from entire xml document mismatches with number of processed elements, unitProcessed = %d, total = %d",self.unitProcessed,total];
        }
    }
#endif
    self.isInLoading = NO;
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.connection = nil;
    self.cumulativeData = nil;
    if (self.timeout < MAX_TIMEOUT) {
        self.timeout += TIMEOUT_STEP;
        ++self.reloadAttemptsMade;
        [self performSelector:@selector(loadAsynchronously) withObject:nil afterDelay:self.timeout];
    }  else {
        self.isInLoading = NO;
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{ATTEMPTS_KEY:[NSString stringWithFormat:@"%d",self.reloadAttemptsMade]}];
        [userInfo addEntriesFromDictionary:error.userInfo];
        NSError *finalError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:[userInfo copy]];
        if([self.delegate respondsToSelector:@selector(DID_FAIL_LOADING_SELECTOR)]){
            [self.delegate performSelector:@selector(DID_FAIL_LOADING_SELECTOR) withObject:self withObject:finalError];
        }
    }
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0){
        NSURLCredential *newCredential = [NSURLCredential credentialWithUser:[[self class] username] password:[[self class] password] persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        NSError *error = [NSError errorWithDomain:HSFAuthenticationErrorDomain code:403 userInfo:nil];
        if ([self.delegate respondsToSelector:@selector(DID_FAIL_AUTH_SELECTOR)]){
            [self.delegate performSelector:@selector(DID_FAIL_AUTH_SELECTOR) withObject:self withObject:error];
        }
    }
}

#pragma mark Private Methods

-(void)performParseOperation:(void (^)())block
{
    if (self.isParseUnitsAsynchronously) {
        ++self.unitInProgress;
        dispatch_async(self.parseQueue, ^{
            block();
            --self.unitInProgress;
        });
    } else {
        block();
    }
}

@end
