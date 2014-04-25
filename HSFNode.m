//
//  HSFNode.m
//  HSFramework
//
//  Created by Ilnar Aliullov on 19/03/14.
//  Copyright (c) 2014 Ilnar Aliullov. All rights reserved.
//

#import "HSFNode.h"
#import "HSFExceptions.h"

@interface HSFNode()

@property (strong,nonatomic,readwrite) HSFNode *parent;
@property (strong,nonatomic) NSMutableArray *mutableChildren;

@end

@implementation HSFNode

#pragma mark Properties

-(HSFNode*)searchNodeByName:(NSString*)name
{
    if ([self.children count]){
        NSUInteger index = [self.children indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            HSFNode *node = (HSFNode*)obj;
            return [name isEqualToString:node.name];
        }];
        if (index != NSNotFound){
            return self.children[index];
        } else {
            for (HSFNode *node in self.children){
                HSFNode *testNode = [node searchNodeByName:name];
                if  (testNode) return testNode;
            }
        }
    }
    
    return nil;
}

-(HSFNode*)rootNode
{
    if (self.parent == nil){
        return self;
    } else {
        return self.parent.rootNode;
    }
}

-(NSString*)value
{
    if(!_value)_value = @"";
    return _value;
}

-(NSDictionary*)dictionary
{
    NSDictionary *result;
    
    if ([self.children count] > 0){
        NSMutableDictionary* subResult = [[NSMutableDictionary alloc] init];
        for (HSFNode* node in self.children){
            if ([[subResult allKeys] containsObject:node.name]){
                [NSException raise:HSFNodeTreeIsNotConvertableToNSDictionary format:@"HSFNode tree structure contains duplicate keys = '%@'",node.name];
            }
            [subResult addEntriesFromDictionary:node.dictionary];
        }
        result = @{self.name: [subResult copy]};
    } else {
        result = @{self.name: self.value};
    }
    
    return result;
}

-(NSDictionary*)attributes
{
    if(!_attributes)_attributes = @{};
    return _attributes;
}

-(NSMutableArray*)mutableChildren
{
    if(!_mutableChildren)_mutableChildren = [[NSMutableArray alloc] init];
    return _mutableChildren;
}

-(NSArray*)children
{
    return [self.mutableChildren copy];
}

-(NSData*)treeData
{
    if (self.parent){
        return [self.parent treeData];
    } else{
        return _treeData;
    }
}

-(void)setTreeData:(NSData *)treeData
{
    if (self.parent){
        self.parent.treeData = treeData;
    } else {
        _treeData = treeData;
    }
}

@synthesize treeData = _treeData;

#pragma mark Public Methods

-(NSUInteger)countOfNodesByName:(NSString *)name
{
    NSUInteger count = 0;
    if ([name isEqualToString:[self name]]) count++;
    if ([self.children count] > 0){
        for (HSFNode *node in self.children){
            count += [node countOfNodesByName:name];
        }
    }
    return count;
}

-(HSFNode*)firstNonsingleParent
{
    if ([self.children count] > 1)
        return self;
    
    if ([self.children count] == 1){
        HSFNode *singleton = self.children[0];
        return [singleton firstNonsingleParent];
    } else
        return nil;
}

-(id)initWithName:(NSString*)name
{
    self = [super init];
    
    if (self){
        if (![name length]){
            [NSException raise:NSInvalidArgumentException format:@"name is nil or empty."];
        }
        _name = name;
    }
    
    return self;
}

-(id)init
{
    [NSException raise:NSInternalInconsistencyException format:@"Use designated initializer."];
    return [super init];
}

-(void)addChild:(HSFNode *)node
{
    if (!node)
        [NSException raise:HSFNodeChildNil format:@"Child is nil."];
    node.parent = self;
    [self.mutableChildren addObject:node];
}

/*
 Override the inherited method.
 */
-(NSString*)description
{
    // static wouldn't cause problem here.
    static int j = 0;
    
    NSMutableString *desc = [[NSMutableString alloc] init];
    [desc appendString:@"\n"];
    for (int i=0;i<=j;++i)
        [desc appendString:@"--|"];
    [desc appendFormat:@"%@: '%@'",self.name, [self.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    if ([self.children count] > 0){
        ++j;
        for (HSFNode *child in self.children){
            [desc appendFormat:@"%@",[child description]];
        }
        --j;
    }
    return [desc mutableCopy];
}

@end
