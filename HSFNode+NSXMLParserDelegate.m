//
//  HSFNode+NSXMLParserDelegate.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 21/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFNode+NSXMLParserDelegate.h"
#import "HSFExceptions.h"
#import "HSFCommon.h"

@implementation HSFNode (NSXMLParserDelegate)

+(HSFNode*)nodeTreeFromData:(NSData*)data delegate:(id<HSFNodeParseErrorHandler>)delegate
{
    HSFNode *root = [[HSFNode alloc] initWithName:ROOT_NODE_NAME];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    parser.delegate = root;
    root.treeData = data;
    root.parseErrorHandler = delegate;
    [parser parse];
    return root;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    HSFNode * newNode = [[HSFNode alloc] initWithName:elementName];
    newNode.attributes = attributeDict;
    
    [self addChild:newNode];
    [parser setDelegate:newNode];
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(![self.value length]){
        self.value = string;
    }else{
        self.value = [NSString stringWithFormat:@"%@%@",self.value,string];
    }
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (self.parent)
        parser.delegate = self.parent;
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
//    [NSException raise:HSFXMLParserException format:@"treeData: %@\nparserError:%@",[[NSString alloc] initWithData:self.treeData encoding:NSUTF8StringEncoding], parseError];
    [self.rootNode.parseErrorHandler node:self didFailParsingWithError:parseError];
}

@end
