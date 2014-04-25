//
//  HSFCatcher.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 18/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFCatcher.h"
#import "HSFAction.h"
#import "HSFCommon.h"
#import "HSFExceptions.h"

static id <HSFCatcherHandler> _handler;

@interface HSFCatcher()

/*
 Temporary storage for received data
 */
@property (strong, nonatomic) NSMutableData *cumulativeData;

// Make writeable properties at private side.
@property (nonatomic,readwrite) BOOL isInLoading;
@property (nonatomic,readwrite) NSUInteger unitRecognized;
@property (nonatomic,readwrite) NSUInteger unitProcessed;
@property (strong,nonatomic,readwrite) NSURLRequest *fixedRequest;
@property (strong,nonatomic,readwrite) NSURLConnection *connection;

@property (nonatomic) NSInteger unitInProgress;
@property (strong,nonatomic) dispatch_queue_t parseQueue;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) NSUInteger failAttemptsMade;
@property (strong,nonatomic) NSString *fixedTag;
@property (strong,nonatomic) NSMutableString *bufferString;

@property (nonatomic) NSUInteger loadAttempts;
@property (nonatomic) NSTimeInterval maxTimeout;
@property (strong,nonatomic) NSURLCredential *credential;

@end

@implementation HSFCatcher

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
    return (self.unitInProgress) ? YES : NO;
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

+(HSFNode*)loadSynchronouslyWithAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error;
{
    NSData *data = [NSURLConnection sendSynchronousRequest:action.request returningResponse:response error:error];
    return [HSFNode nodeTreeFromData:data delegate:nil];
}

-(void)loadAsynchronouslyWithAction:(HSFAction*)action
{
    if (!self.delegate || !action){
        [NSException raise:NSInvalidArgumentException format:@"The delegate or action is not set."];
    }
    // Fix request and copy required information from action.
    self.isInLoading = YES;
    self.fixedRequest = action.request;
    self.credential = action.credential;
    self.loadAttempts = action.loadAttempts;
    self.maxTimeout = action.maxTimeout;
    self.unitTags = [action.unitTags copy];
    self.parseUnitsAsynchronously = action.parseUnitsAsynchronously;
    self.connection = [[NSURLConnection alloc] initWithRequest:self.fixedRequest delegate:self];
}

-(void)reloadAsynchronously
{
    if (!self.fixedRequest)
        [NSException raise:NSInvalidArgumentException format:@"The fixedRequest is not set."];
    self.connection = [[NSURLConnection alloc] initWithRequest:self.fixedRequest delegate:self];
}

-(id)initWithDelegate:(id <HSFCatcherDelegate>)delegate
{
    self = [super init];
    
    if (!delegate){
        [NSException raise:NSInvalidArgumentException format:@"The delegate is nil."];
    }
    
    if (self){
        _delegate = delegate;
        _parseUnitsAsynchronously = NO;
        _isInLoading = NO;
    }
    
    return self;
}

-(id)init
{
    [NSException raise:NSInternalInconsistencyException format:@"Use designated initializer."];
    return [super init];
}

#pragma mark HSFNodeParseErrorHandler protocol

-(void)node:(HSFNode *)node didFailParsingWithError:(NSError *)error
{
    NSError *parseError = [[NSError alloc] initWithDomain:HSFParseErrorDomain code:1 userInfo:nil];
    [self.connection cancel];
    [self notifyDelegateFailLoadingWithError:parseError];
}

#pragma mark NSURLConnectionDataDelegate

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.cumulativeData setLength:0];
    self.unitInProgress = 0;
    self.unitRecognized = 0;
    self.unitProcessed = 0;
    self.timeout = 0.0;
    self.failAttemptsMade = 0;
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
                    HSFNode *root = [HSFNode nodeTreeFromData:dataToParse delegate:self];
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
        HSFNode* root = [HSFNode nodeTreeFromData:self.cumulativeData delegate:self];
        // root is pointer to tree root element
        [self.delegate performSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR) withObject:self withObject:[root.children firstObject]];
    }
    
    // Perform this text only in DEBUG mode.
#ifdef DEBUG
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR)] && [self.unitTags count] > 0){
        HSFNode* root = [HSFNode nodeTreeFromData:self.cumulativeData delegate:self];
        NSUInteger total = 0;
        for (NSString *tag in self.unitTags){
            total += [root countOfNodesByName:tag];
        }
        if (self.isParseUnitsAsynchronously) while (self.isParsing) {};
        if (self.unitProcessed != total){
            [NSException raise:HSFCatcherMissedElementException format:@"Number of elements counted from entire xml document mismatches with number of processed elements, unitProcessed = %d, total = %d",self.unitProcessed,total];
        }
    }
#endif
    [self finishJobAndHotifyHandler];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.connection = nil;
    self.cumulativeData = nil;
    ++self.failAttemptsMade;
    if ((self.loadAttempts > 1) && self.maxTimeout && self.timeout < self.maxTimeout) {
        self.timeout += (double)self.maxTimeout/(self.loadAttempts-1);
        [self performSelector:@selector(reloadAsynchronously) withObject:nil afterDelay:self.timeout];
    }  else {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{ATTEMPTS_KEY:[NSString stringWithFormat:@"%d",self.failAttemptsMade]}];
        [userInfo addEntriesFromDictionary:error.userInfo];
        NSError *finalError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:[userInfo copy]];
        [self notifyDelegateFailLoadingWithError:finalError];
    }
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0){
        [[challenge sender] useCredential:self.credential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        NSError *error = [NSError errorWithDomain:HSFAuthenticationErrorDomain code:403 userInfo:nil];
        [self notifyDelegateAuthenticationFailWithError:error];
    }
}

#pragma mark Private Methods

-(void)notifyDelegateAuthenticationFailWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(DID_FAIL_AUTH_SELECTOR)]){
        [self.delegate performSelector:@selector(DID_FAIL_AUTH_SELECTOR) withObject:self withObject:error];
    }
    [self finishJobAndHotifyHandler];
}

-(void)notifyDelegateFailLoadingWithError:(NSError*)error
{
    if([self.delegate respondsToSelector:@selector(DID_FAIL_LOADING_SELECTOR)]){
        [self.delegate performSelector:@selector(DID_FAIL_LOADING_SELECTOR) withObject:self withObject:error];
    }
    [self finishJobAndHotifyHandler];
}

-(void)finishJobAndHotifyHandler
{
    self.connection =nil;
    self.isInLoading = NO;
    [[[self class] handler] catcherFinished:self];
}

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

#pragma mark Class Methods

+(id<HSFCatcherHandler>)handler
{
    if (!_handler){
        [NSException raise:NSInvalidArgumentException format:@"The class hanlder is nil."];
    }
    return _handler;
}

+(void)setHandler:(id<HSFCatcherHandler>)handler
{
    _handler = handler;
}

@end
