//
//  HSFNode+NSXMLParserDelegate.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 21/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFNode.h"

/*!
 @abstract Category to make a HSFNode be a NSXMLParserDelegate.
 @discussion This category applies parser delegate responsibilities on HSFNode. Each node will be a delegate in turn to build an XML document tree structure. Inspired by Apple's "Event-Driven XML Programming Guide".
 */
@interface HSFNode (NSXMLParserDelegate) <NSXMLParserDelegate>

/*!
 @abstract Parse data and return node tree.
 @discussion This task uses given data bag and returns node tree or throw exception if data is not valid XML document.
 @param data Data bag to parse.
 @param delegate Hadler to notify about parsing error.
 @return Root node with name of ROOT_NODE_NAME macro. Note that this root node itself is not a part of a given XML data.
 */
+(HSFNode*)nodeTreeFromData:(NSData*)data delegate:(id<HSFNodeParseErrorHandler>)delegate;

/*!
 @abstract Handle open tag.
 @discussion This task creates a new node and add sets it as a child of the current node. It the new node as parser delegate.
 */
-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;

/*!
 @abstract Handle data inside a tag.
 @discussion Appends character to the node's value.
 */
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;

/*!
 @abstract Handle close tag.
 @discussion Sets parent as parser delegate.
 */
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

/*!
 @abstract Handle parser error.
 @discussion Throws an exception if parse error occurred and prints treeData.
 */
-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end

/*!
 @abstract Parsing error handler protocol.
 */
@protocol HSFNodeParseErrorHandler <NSObject>

/*!
 @abstract This notification will be sent to handler when parsing error will occur.
 */
-(void)node:(HSFNode*)node didFailParsingWithError:(NSError*)error;

@end
