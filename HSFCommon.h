//
//  HSFCommon.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 19/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#define HSF_ACTION_CLASS_NAME @"HSFAction"

/*!
 @abstract Time interval in seconds.
 @discussion With this interval attempts to reload asynchronously will be made.
 */
#define MAX_TIMEOUT 63.0
/*!
 @abstract Number of reload attempts.
 @discussion This number of attempts will be made to try to load asynchronously, including very first attempt.
 */
#define ATTEMPTS 11
#define TIMEOUT_STEP (double)MAX_TIMEOUT/(ATTEMPTS-1)

#define ATTEMPTS_KEY @"attempts"
#define POST_METHOD @"POST"
#define CONTENT_TYPE @"Content-Type"
#define CONTENT_LENGTH @"Content-Length"


#define DID_FAIL_LOADING_SELECTOR client:didFailLoadingWithError:
#define DID_FAIL_AUTH_SELECTOR client:didFailAuthenticationWithError:
#define CLIENT_DID_RECEIVE_UNIT_SELECTOR client:didReceiveUnit:
#define CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR client:didReceiveEntireResponse:

#define PARSE_QUEUE "Parse queue"
#define ROOT_NODE_NAME @"root"

/*!
 @abstract Authentication error domain.
 @discussion Error occurred during authentication process.
 */
#define HSFAuthenticationErrorDomain @"HSFAuthenticationErrorDomain"