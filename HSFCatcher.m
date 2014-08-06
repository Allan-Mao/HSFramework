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
@property (strong,nonatomic,readwrite) NSURLConnection *connection;

@property (nonatomic) NSInteger unitInProgress;
@property (strong,nonatomic) dispatch_queue_t parseQueue;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) NSUInteger failAttemptsMade;

@property (strong,nonatomic) NSString *fixedTag;
@property (strong,nonatomic) NSString *openTag;
@property (strong,nonatomic) NSMutableString *bufferString;
@property (strong,nonatomic) NSString *closedTag;

@property (strong,nonatomic,readwrite) HSFActionStamp *actionStamp;

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

-(NSMutableData*)cumulativeData
{
    if (!_cumulativeData)_cumulativeData = [[NSMutableData alloc] init];
    return _cumulativeData;
}

#pragma mark Public Methods

-(void)cancel
{
    [self finishJobAndHotifyHandler];
}

//TODO: shift it to HSFCliene,rework, rethink, reconsider.
+(HSFNode*)loadSynchronouslyWithAction:(HSFAction*)action response:(NSURLResponse **)response error:(NSError **)error;
{
    NSData *data = [NSURLConnection sendSynchronousRequest:action.request returningResponse:response error:error];
    NSError *parseError;
    HSFNode * root = [HSFNode nodeTreeFromData:data error:&parseError];
    if (parseError != NULL) *error = parseError;
    if ([root.children count]){
        return [root.children firstObject];
    } else {
        return nil;
    }
}

-(void)loadAsynchronouslyWithAction:(HSFAction*)action
{
    if (self.isInLoading){
        [NSException raise:NSInvalidArgumentException format:@"Attempt to loadAsynchronously while catcher isInLoading."];
    }
    
    self.isInLoading = YES;
    
    // Fix action in the actionStamp
    self.actionStamp = [[HSFActionStamp alloc] initWithAction:action];
    
    [self startNetworkingProcess];
}

-(id)initWithDelegate:(id <HSFCatcherDelegate>)delegate
{
    self = [super init];
    
    if (!delegate){
        [NSException raise:NSInvalidArgumentException format:@"The delegate is nil."];
    }
    
    if (self){
        _delegate = delegate;
        _isInLoading = NO;
    }
    
    return self;
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
    self.failAttemptsMade = 0;
    if ([self.delegate respondsToSelector:@selector(CATCHER_DID_RECEIVE_RESPONSE_SELECTOR)])
        [self.delegate performSelector:@selector(CATCHER_DID_RECEIVE_RESPONSE_SELECTOR) withObject:self withObject:response];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([data length] == 0)
        //TODO: Get rid of this exception.
        [NSException raise:HSFServiceResponseException format:@"Server should not return empty data in SOAP exchange."];
    
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR)])
        [self.cumulativeData appendData:data];
    
    if ([self.actionStamp.unitTags count] > 0 && ![self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR)])
        [NSException raise:HSFCatcherSpecialTagsException format:@"HSFCatcher unit tags are defined, but delegate does not responds for the selector."];
    
    if ([self.actionStamp.streamingTags count] > 0 && ![self.delegate respondsToSelector:@selector(CATCHER_DID_RECEIVE_CONTENT_SELECTOR)])
        [NSException raise:HSFCatcherSpecialTagsException format:@"HSFCatcher streming tags are defined, but delegate does not responds for the selector."];
    
    
    //Order matter!
    NSArray *specialTags;
    if ([self.actionStamp.orderedSpecialTags count]){
        if ([self.actionStamp.orderedSpecialTags count] != [self.actionStamp.unitTags count] + [self.actionStamp.streamingTags count])
            [NSException raise:HSFCatcherSpecialTagsException format:@"HSFCatcher orderedSpecialTags number is not equal to unitTag and streamingTags number."];
        specialTags = [self.actionStamp.orderedSpecialTags mutableCopy];
    } else {
        NSMutableArray *arr = [[NSMutableArray alloc] initWithArray:self.actionStamp.unitTags];
        [arr removeObjectsInArray:self.actionStamp.streamingTags];
        specialTags = [self.actionStamp.streamingTags arrayByAddingObjectsFromArray:arr];
    }
    
    if ([specialTags count] > 0){
    
        NSString *stringToProcess;
        
        if (!self.bufferString){
            self.bufferString = [[NSMutableString alloc] init];
        }
        [self.bufferString appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        
        NSRange range;
        BOOL isNeedNewData = NO;
        
        //Start process received string.
        while (!isNeedNewData){
            
            // Search if non of the tags is found.
            if ([self.fixedTag length] == 0){
                for (NSString *tag in specialTags){
                    NSString *openTag_pattern = [NSString stringWithFormat:@"<%@(( [^>]*>)|>)",tag];
                    range = [self.bufferString rangeOfString:openTag_pattern options:NSRegularExpressionSearch|NSCaseInsensitiveSearch];
                    if (range.location != NSNotFound){
                        self.fixedTag = tag;
                        self.openTag = [self.bufferString substringWithRange:range];
                        //Cutting buffer
                        [self.bufferString deleteCharactersInRange:NSMakeRange(0, range.location+range.length)];
                        range = [self.openTag rangeOfString:@"/>"];
                        if (range.location != NSNotFound){
                            self.closedTag = self.openTag;
                            stringToProcess = @"";
                        }
                        break;
                    }
                }
            }
            
            // Free buffer string if data is not broken in the middle of the tag e.g. "djkaafsdf<AudioDa.."
            if ([self.fixedTag length] == 0){
                isNeedNewData = YES;
                if (![self isTagBreakingString:self.bufferString]){
                    self.bufferString = nil;
                    break;
                }
            }
            
            if ([self.fixedTag length] && ![self.closedTag length]){
                NSString *closedTag_template = [NSString stringWithFormat:@"</%@>", self.fixedTag];
                range = [self.bufferString rangeOfString:closedTag_template options:NSCaseInsensitiveSearch];
                if (range.location != NSNotFound){
                    self.closedTag = [self.bufferString substringWithRange:range];
                    stringToProcess = [self.bufferString substringToIndex:range.location];
                    [self.bufferString setString:[self.bufferString substringFromIndex:(range.location+range.length)]];
                } else {
                    isNeedNewData = YES;
                }
            }
            
            if ([self.closedTag length] && ![self.openTag length]){
                [NSException raise:HSFCatcherSpecialTagsException format:@"HSFCatcher openTag is empty while closed is set"];
            }
            
            if ([self.openTag length] && [self.actionStamp.streamingTags containsObject:self.fixedTag] && [self.delegate respondsToSelector:@selector(CATCHER_DID_RECEIVE_CONTENT_SELECTOR)]){
                if ([self.closedTag length]){
                    [self.delegate catcher:self didReceiveContent:stringToProcess forTag:self.fixedTag lastChunk:YES];
                    stringToProcess = nil;
                    self.openTag = nil;
                    self.closedTag = nil;
                    self.fixedTag = nil;
                } else if (![self isTagBreakingString:self.bufferString]){
                    [self.delegate catcher:self didReceiveContent:self.bufferString forTag:self.fixedTag lastChunk:NO];
                    self.bufferString = nil;
                }
            }
            
            if ([self.closedTag length] && [self.actionStamp.unitTags containsObject:self.fixedTag] && [self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR)]){
                ++self.unitRecognized;
                if ([stringToProcess length]){
                    stringToProcess = [NSString stringWithFormat:@"%@%@%@",self.openTag,stringToProcess,self.closedTag];
                } else {
                    stringToProcess = self.closedTag;
                }
                NSData *dataToParse = [stringToProcess dataUsingEncoding:NSUTF8StringEncoding];
                
                [self performParseOperation:^{
                    NSError *parseError;
                    HSFNode *root = [HSFNode nodeTreeFromData:dataToParse error:&parseError];
                    ++self.unitProcessed;
                    if (!parseError) {
                        [self.delegate performSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR) withObject:self withObject:[root.children firstObject]];
                    } else {
                        [self.connection cancel];
                        [self connection:self.connection didFailWithError:parseError];
                        return;
                    }
                }];
                self.openTag = nil;
                self.closedTag = nil;
                self.fixedTag = nil;
                stringToProcess = nil;
            }
        }
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
//    if ([self.cumulativeData length] == 0)
//        [NSException raise:HSFServiceResponseException format:@"No data received while loading."];
    
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR)]){
        NSError *parseError;
        HSFNode* root = [HSFNode nodeTreeFromData:self.cumulativeData error:&parseError];
        // root is pointer to tree root element
        if (!parseError) {
            [self.delegate performSelector:@selector(CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR) withObject:self withObject:[root.children firstObject]];
        } else {
            [self.connection cancel];
            [self connection:self.connection didFailWithError:parseError];
            return;
        }
    }
    
    // Perform this text only in DEBUG mode.
#ifdef DEBUG
    if ([self.delegate respondsToSelector:@selector(CLIENT_DID_RECEIVE_UNIT_SELECTOR)] && [self.actionStamp.unitTags count] > 0 && [self.cumulativeData length] > 0){
        HSFNode* root = [HSFNode nodeTreeFromData:self.cumulativeData error:NULL];
        NSUInteger total = 0;
        for (NSString *tag in self.actionStamp.unitTags){
            total += [root countOfNodesByName:tag];
        }
        if (self.actionStamp.isParseUnitsAsynchronously) while (self.isParsing) {};
        if (self.unitProcessed != total){
            [NSException raise:HSFCatcherMissedElementException format:@"Number of elements counted from entire xml document mismatches with number of processed elements, unitProcessed = %d, total = %d",self.unitProcessed,total];
        }
    }
#endif
    [self finishJobAndHotifyHandler];
    
    if ([self.delegate respondsToSelector:@selector(CATCHER_DID_FINISH_LOADING_SELECTOR)])
        [self.delegate performSelector:@selector(CATCHER_DID_FINISH_LOADING_SELECTOR) withObject:self];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    ++self.failAttemptsMade;
    if ((self.actionStamp.loadAttempts > 1) && self.actionStamp.maxTimeout && self.timeout < self.actionStamp.maxTimeout) {
        self.timeout += (double)self.actionStamp.maxTimeout/(self.actionStamp.loadAttempts-1);
        [self finishNetworkingProcess];
        [self performSelector:@selector(reloadAsynchronously) withObject:nil afterDelay:self.timeout];
    }  else {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{ATTEMPTS_KEY:[NSString stringWithFormat:@"%lu",(unsigned long)self.failAttemptsMade]}];
        [userInfo addEntriesFromDictionary:error.userInfo];
        NSError *finalError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:[userInfo copy]];
        if ([[[self class] networkErrorCodes] containsObject:[NSNumber numberWithInteger:[error code]]]){
            [self notifyDelegateFailConnectionWithError:finalError];
        } else {
            [self notifyDelegateFailLoadingWithError:finalError];
        }
    }
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0){
        [[challenge sender] useCredential:self.actionStamp.credential forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        NSError *error = [NSError errorWithDomain:HSFAuthenticationErrorDomain code:403 userInfo:nil];
        [self notifyDelegateAuthenticationFailWithError:error];
    }
}

#pragma mark Private Methods

-(void)reloadAsynchronously
{
    if (!self.isInLoading){
        [NSException raise:NSInvalidArgumentException format:@"Attempt to loadAsynchronously while catcher isInLoading = NO."];
    }
    
    [self startNetworkingProcess];
}

+(NSArray*)networkErrorCodes
{
    static NSArray *codesArray;
    if (![codesArray count]){
        @synchronized(self){
            const int codes[] = {
                //kCFURLErrorUnknown,     //-998
                //kCFURLErrorCancelled,   //-999
                //kCFURLErrorBadURL,      //-1000
                //kCFURLErrorTimedOut,    //-1001
                //kCFURLErrorUnsupportedURL, //-1002
                //kCFURLErrorCannotFindHost, //-1003
                kCFURLErrorCannotConnectToHost,     //-1004
                kCFURLErrorNetworkConnectionLost,   //-1005
                kCFURLErrorDNSLookupFailed,         //-1006
                //kCFURLErrorHTTPTooManyRedirects,    //-1007
                kCFURLErrorResourceUnavailable,     //-1008
                kCFURLErrorNotConnectedToInternet,  //-1009
                //kCFURLErrorRedirectToNonExistentLocation,   //-1010
                kCFURLErrorBadServerResponse,               //-1011
                //kCFURLErrorUserCancelledAuthentication,     //-1012
                //kCFURLErrorUserAuthenticationRequired,      //-1013
                //kCFURLErrorZeroByteResource,        //-1014
                //kCFURLErrorCannotDecodeRawData,     //-1015
                //kCFURLErrorCannotDecodeContentData, //-1016
                //kCFURLErrorCannotParseResponse,     //-1017
                kCFURLErrorInternationalRoamingOff, //-1018
                kCFURLErrorCallIsActive,                //-1019
                //kCFURLErrorDataNotAllowed,              //-1020
                //kCFURLErrorRequestBodyStreamExhausted,  //-1021
                kCFURLErrorFileDoesNotExist,            //-1100
                //kCFURLErrorFileIsDirectory,             //-1101
                kCFURLErrorNoPermissionsToReadFile,     //-1102
                //kCFURLErrorDataLengthExceedsMaximum,     //-1103
            };
            int size = sizeof(codes)/sizeof(int);
            NSMutableArray *array = [[NSMutableArray alloc] init];
            for (int i=0;i<size;++i){
                [array addObject:[NSNumber numberWithInt:codes[i]]];
            }
            codesArray = [array copy];
        }
    }
    return codesArray;
}

-(void)notifyDelegateAuthenticationFailWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(DID_FAIL_AUTH_SELECTOR)]){
        [self.delegate performSelector:@selector(DID_FAIL_AUTH_SELECTOR) withObject:self withObject:error];
    }
    // This callback will cause two notification probably, as auth error will be sent as genrail didReceiveError.
    //[self notifyDelegateCommonFailWithError:error];
}

-(void)notifyDelegateFailLoadingWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(DID_FAIL_LOADING_SELECTOR)]){
        [self.delegate performSelector:@selector(DID_FAIL_LOADING_SELECTOR) withObject:self withObject:error];
    }
    [self notifyDelegateCommonFailWithError:error];
    [self finishJobAndHotifyHandler];
}

-(void)notifyDelegateFailConnectionWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(DID_FAIL_CONNECTION_SELECTOR)]){
        [self.delegate performSelector:@selector(DID_FAIL_CONNECTION_SELECTOR) withObject:self withObject:error];
    }
    [self notifyDelegateCommonFailWithError:error];
    [self finishJobAndHotifyHandler];
}

-(void)notifyDelegateCommonFailWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(DID_FAIL_COMMON_SELECTOR)]){
        [self.delegate performSelector:@selector(DID_FAIL_COMMON_SELECTOR) withObject:self withObject:error];
    }
}

-(void)finishJobAndHotifyHandler
{
    self.isInLoading = NO;
    [self finishNetworkingProcess];
}

/*
 Common point to start any network activity.
 */
-(void)startNetworkingProcess
{
    if (!self.delegate || !self.actionStamp.request){
        [NSException raise:NSInvalidArgumentException format:@"The delegate or action is not set."];
    }
    
    [[[self class] handler] catcherStarted:self];
    self.connection = [[NSURLConnection alloc] initWithRequest:self.actionStamp.request delegate:self];
}

-(void)finishNetworkingProcess
{
    [self.connection cancel];
    self.connection = nil;
    self.cumulativeData = nil;
    [[[self class] handler] catcherFinished:self];
    
}

-(void)performParseOperation:(void (^)())block
{
    if (self.actionStamp.isParseUnitsAsynchronously) {
        ++self.unitInProgress;
        dispatch_async(self.parseQueue, ^{
            block();
            --self.unitInProgress;
        });
    } else {
        block();
    }
}

-(BOOL)isTagBreakingString:(NSString*)string
{
    NSRange lessThanSignRange = [self.bufferString rangeOfString:@"<" options:NSBackwardsSearch];
    if (lessThanSignRange.location == NSNotFound){
        return NO;
    } else {
        NSRange greatThanSignRange = [self.bufferString rangeOfString:@">" options:NSBackwardsSearch];
        if (greatThanSignRange.location != NSNotFound && greatThanSignRange.location > lessThanSignRange.location){
            return NO;
        }
    }
    return YES;
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
