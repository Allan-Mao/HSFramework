//
//  HSFCommon.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 19/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#define HSF_ACTION_CLASS_NAME @"HSFAction"
#define HSF_PARSE_ERROR_KEY @"parseError"

#define ATTEMPTS_KEY @"attempts"
#define POST_METHOD @"POST"
#define CONTENT_TYPE @"Content-Type"
#define CONTENT_LENGTH @"Content-Length"


#define DID_FAIL_LOADING_SELECTOR catcher:didFailLoadingWithError:
#define DID_FAIL_CONNECTION_SELECTOR catcher:didFailConnectionWithError:
#define DID_FAIL_AUTH_SELECTOR catcher:didFailAuthenticationWithError:
#define DID_FAIL_COMMON_SELECTOR catcher:didFailWithCommonError:
#define CLIENT_DID_RECEIVE_UNIT_SELECTOR catcher:didReceiveUnit:
#define CLIENT_DID_RECEIVE_ENTIRE_RESPONSE_SELECTOR catcher:didReceiveEntireResponse:
#define CLIENT_DID_PROGRESS catcher:didProgress:
#define CATCHER_DID_RECEIVE_CONTENT_SELECTOR catcher:didReceiveContent:forTag:lastChunk:
#define CATCHER_DID_RECEIVE_RESPONSE_SELECTOR catcher:didReceiveResponse:
#define CATCHER_DID_FINISH_LOADING_SELECTOR catcherDidFinishLoading:

#define PARSE_QUEUE "Parse queue"
#define ROOT_NODE_NAME @"root"

#define DEFAULT_CONNECTION_TIMEOUT 60.0

/*!
 @abstract Authentication error domain.
 @discussion Error occurred during authentication process.
 */
#define HSFAuthenticationErrorDomain @"HSFAuthenticationErrorDomain"

/*!
 @abstract Parse error domain.
 @discussion Error occurred during parsing process.
 */
#define HSFParseErrorDomain @"HSFParseErrorDomain"

#define HSF_ERROR_CODE_XML_PARSE_ERROR 1
#define HSF_ERROR_MESSAGE_XML_PARSE_ERROR @"XML parsing error occcured."