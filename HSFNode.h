//
//  HSFNode.h
//  HSFramework
//
//  Created by Ilnar Aliullov on 19/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HSFNodeParseErrorHandler;

/*!
 @abstract XML node of SOAP envelope XML document.
 @discussion An instances of this class construct a tree which represents SOAP XML document.
 */
@interface HSFNode : NSObject

/*!
 @abstract Storage to keep any necessary data.
 */
@property (strong,nonatomic) NSDictionary *userInfo;

/*!
 @abstract Parent node.
 @discussion Every node can have multiple children elements and only one parent.
 */
@property (strong,nonatomic,readonly) HSFNode *parent;

/*!
 @abstract Root node of the tree.
 */
@property (nonatomic,readonly) HSFNode *rootNode;

/*!
 @abstract Dictionary derived from the node tree.
 @discussion If node tree is one-one converted to NSDictionary it returns dictionary, if not it throws an exception. Tree is not convertible to dictionary e.g. when there are sibling nodes with the same name.
 */
@property (strong,nonatomic,readonly) NSDictionary *dictionary;

/*!
 @abstract Attributes of the node.
 @discussion These attributes represent xml tag's attributes.
 */
@property (strong,nonatomic) NSDictionary *attributes;

/*!
 @abstract Raw tree data used to constitute the tree.
 @discussion Only root tree instance should has this value.
 */
@property (strong,nonatomic) NSData *treeData;

/*!
 @abstract Value of the Node.
 @discussion Represents content of XML tag.
 */
@property (strong,nonatomic) NSString *value;

/*!
 @abstract Name of the node.
 @discussion This name represents tag of the XML document.
 */
@property (strong,nonatomic,readonly) NSString *name;

/*!
 @abstract Children of the node.
 @discussion Array of children nodes, each of them, must have the node as a parent.
 */
@property (strong,nonatomic,readonly) NSArray *children; //Of nodes

#pragma mark Tasks

/*!
 @abstract Search node's tree for node with specified name.
 @param name Name of an element to search.
 @retrun Node with specified name or nil.
 */
-(HSFNode*)searchNodeByName:(NSString*)name;

/*!
 @abstract Count of nodes with specified name.
 @discussion Goes through the entire tree and count all elements with specified name.
 @param name Name to search.
 @return Number of element with specified name.
 */
-(NSUInteger)countOfNodesByName:(NSString*)name;

/*!
 @abstract First nonsingle parent element in the tree.
 @discussion Occasionally tree data from xml document will contain a bunch of wrapping elements. This method returns a node which likely has sense. If tree contains only single parents, it returns nil.
 @return The node which is nonsingle parent or nil.
 */
-(HSFNode*)firstNonsingleParent;

/*!
 @abstract Designated initializer.
 @discussion Returns an initialized node with specified name.
 @param name Name of the node. Must no be nil.
 @return The initialized node.
 */
-(id)initWithName:(NSString*)name;

/*!
 @abstract Add child.
 @discussion This method adds a child to the current node and sets itself as its parent. Throws an exception if the child is nil.
 @param node Node to be a child.
 */
-(void)addChild:(HSFNode*)node;

@end
