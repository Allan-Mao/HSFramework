//
//  HSFExceptions.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 21/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

/*!
 @definedblock Exceptions
 @abstract Exceptions raise by framework.
 @discussion These exceptions are thrown in certain inconsistent conditions. Predefined exceptions are also used.
 */

/*!
 @define HSFInvalidXMLException
 @abstract Invalid XML document.
 @discussion The Exception is raised when xml document is not valid, and that means some a inconsistency int the system.
 */
#define HSFInvalidXMLException @"HSFInvalidXMLException"

/*!
 @define HSFNodeTreeIsNotConvertableToNSDictionary
 @abstract HSFNode is not convertible to NSDictionary.
 @discussion The Exception is raised when HSFNode tree structure is not one-one convertible to NSDictionary.
 */
#define HSFNodeTreeIsNotConvertableToNSDictionary @"HSFNodeTreeIsNotConvertableToNSDictionary"

/*!
 @abstract XML parser error occurred.
 @discussion The exception is raised when received SOAP XML response or specially recognized unit is not valid XML document.
 */
#define HSFXMLParserException @"HSFXMLParserException"

/*!
 @abstract SOAP service response is invalid.
 @discussion The exception is raised when received response is not expected.
 */
#define HSFServiceResponseException @"HSFServiceResponseException"

/*!
 @abstract HSFCatcher missed an element.
 @discussion The exception is raised when HSFCatcher missed an element while extracting specialized units. The test performed only in DEBUG mode.
 */
#define HSFCatcherMissedElementException @"HSFCatcherMissedElementException"

/*!
 @abstract HSFCatcher special tags inconsistency.
 @discussion The exception could be raised when HSFCatcher is dealing with unit or streaming tags.
 */
#define HSFCatcherSpecialTagsException @"HSFCatcherSpecialTagsException"

/*!
 @abstract NSFNode child is nil.
 @discussion The exception is raised when nil added as a child to NSFNode. This is needed for additional error detection in parsing.
 */
#define HSFNodeChildNil @"HSFNodeChildNil"

/*!
 @abstract NSFAbstract method or class was not implemented.
 @discussion Objective-C classes are abstract by convention only. So we throws exceptions in case of obligatory overridden methods or classes.
 */
#define HSFAbstractNotOverridden @"HSFAbstractNotOverridden"

/*! @/definedblock */