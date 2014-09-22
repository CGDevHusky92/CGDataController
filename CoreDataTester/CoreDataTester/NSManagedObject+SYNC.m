//
//  NSManagedObject+SYNC.m
//  ThisOrThat
//
//  Created by Chase Gorectke on 2/23/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import "CGDataController.h"
#import "NSManagedObject+SYNC.h"
#import "objc/runtime.h"

#import "SubTest.h"

@implementation NSManagedObject (SYNC)

@dynamic createdAt;
@dynamic note;
@dynamic objectId;
@dynamic wasDeleted;
@dynamic serverClass;
@dynamic syncStatus;
@dynamic updatedAt;

- (BOOL)updateFromDictionary:(NSDictionary *)dic
{
    [self updateAttributesFromDictionary:dic];
    return [self updateRelationshipsFromDictionary:dic];
}

- (void)updateAttributesFromDictionary:(NSDictionary *)dictionary
{
    NSDictionary * attributes = [[self entity] attributesByName];
    for (NSString * attribute in attributes) {
        id value = [dictionary objectForKey:attribute];
        if (value == nil) continue;
        
        NSAttributeType attributeType = [[attributes objectForKey:attribute] attributeType];
        if ((attributeType == NSStringAttributeType) && ([value isKindOfClass:[NSNumber class]])) {
            value = [value stringValue];
            if ([[self valueForKey:attribute] isEqualToString:value]) continue;
        } else if (((attributeType == NSInteger16AttributeType) || (attributeType == NSInteger32AttributeType) || (attributeType == NSInteger64AttributeType) || (attributeType == NSBooleanAttributeType)) && ([value isKindOfClass:[NSString class]])) {
            value = [NSNumber numberWithInteger:[value integerValue]];
            if ([[self valueForKey:attribute] isEqual:value]) continue;
        } else if ((attributeType == NSFloatAttributeType) &&  ([value isKindOfClass:[NSString class]])) {
            value = [NSNumber numberWithDouble:[value doubleValue]];
            if ([[self valueForKey:attribute] isEqual:value]) continue;
        } else if ((attributeType == NSDateAttributeType) && ([value isKindOfClass:[NSString class]])) {
            value = [[CGDataController sharedData] dateUsingStringFromAPI:value];
            if ([[self valueForKey:attribute] isEqualToDate:value]) continue;
        }
        
        if ([value isKindOfClass:[NSNull class]]) {
            [self setValue:nil forKey:attribute];
        } else {
            [self setValue:value forKey:attribute];
        }
    }
}

- (BOOL)updateRelationshipsFromDictionary:(NSDictionary *)dictionary
{
    BOOL ret = YES;
    NSDictionary *relationships = [[self entity] relationshipsByName];
    for (NSString * relationship in relationships) {
        NSRelationshipDescription * description = [[[self entity] relationshipsByName] objectForKey:relationship];
        if ([description isToMany]) {
            NSArray *objIds = [dictionary valueForKey:relationship];
            if (![objIds isKindOfClass:[NSNull class]]) {
                for (NSString *objId in objIds) {
                    NSString * relDestClass = [[description destinationEntity] managedObjectClassName];
                    NSManagedObject * obj = [[CGDataController sharedData] managedObjectForClass:relDestClass withId:objId];
                    
                    if (obj) {
                        NSString *sel = [NSString stringWithFormat:@"add%@sObject:", [[description destinationEntity] managedObjectClassName]];
                        SEL selSelector = NSSelectorFromString(sel);
                        [self fireSelector:selSelector onObject:self withParameter:obj];
                        
                        SEL objSelector;
                        if ([[description inverseRelationship] isToMany]) {
                            NSString *objSel = [NSString stringWithFormat:@"add%@sObject:", [[self entity] managedObjectClassName]];
                            objSelector = NSSelectorFromString(objSel);
                        } else {
                            NSString *objSel = [NSString stringWithFormat:@"set%@:", [[self entity] managedObjectClassName]];
                            objSelector = NSSelectorFromString(objSel);
                        }
                        [self fireSelector:objSelector onObject:obj withParameter:self];
                    } else {
                        ret = NO;
                    }
                }
            }
        } else {
            NSString * relId = [dictionary valueForKey:relationship];
            if (![relId isKindOfClass:[NSNull class]] && ![relId isKindOfClass:[NSArray class]]) {
                NSString * relDestClass = [[description destinationEntity] managedObjectClassName];
                NSManagedObject * obj = [[CGDataController sharedData] managedObjectForClass:relDestClass withId:[dictionary valueForKey:relationship]];
                
                if (obj) {
                    NSString *sel = [NSString stringWithFormat:@"set%@:", [[description destinationEntity] managedObjectClassName]];
                    SEL selSelector = NSSelectorFromString(sel);
                    [self fireSelector:selSelector onObject:self withParameter:obj];
                    
                    SEL objSelector;
                    if ([[description inverseRelationship] isToMany]) {
                        NSString *objSel = [NSString stringWithFormat:@"add%@sObject:", [[self entity] managedObjectClassName]];
                        objSelector = NSSelectorFromString(objSel);
                    } else {
                        NSString *objSel = [NSString stringWithFormat:@"set%@:", [[self entity] managedObjectClassName]];
                        objSelector = NSSelectorFromString(objSel);
                    }
                    [self fireSelector:objSelector onObject:obj withParameter:self];
                } else {
                    ret = NO;
                }
            }
        }
    }
    
    return ret;
}

- (void)fireSelector:(SEL)select onObject:(id)object withParameter:(id)param
{
    if ([object respondsToSelector:select]) {
        IMP imp = [object methodForSelector:select];
        void (*selector)(id, SEL, NSManagedObject *) = (void *)imp;
        selector(object, select, param);
    }
}

- (NSDictionary *)dictionaryFromObject
{
    NSArray * keys = [[[self entity] attributesByName] allKeys];
    NSMutableDictionary * propDic = [[self dictionaryWithValuesForKeys:keys] mutableCopy];
    [propDic addEntriesFromDictionary:[self relationshipDictionaryFromObject]];
    return propDic;
}

- (NSDictionary *)relationshipDictionaryFromObject
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSDictionary *relationshipsByName = [[self entity] relationshipsByName];
    for (NSString *rel in [relationshipsByName allKeys]) {
        NSRelationshipDescription *description = [relationshipsByName objectForKey:rel];
        if ([description isToMany]) {
            NSMutableArray *objIds = [[NSMutableArray alloc] init];
            NSSet *relationship = [self valueForKey:rel];
            for (NSManagedObject * obj in relationship)
                [objIds addObject:[obj valueForKey:@"objectId"]];
            
            if ([objIds count] > 0)
                [dic setObject:objIds forKey:rel];
            else
                [dic setObject:[NSNull null] forKey:rel];
        } else {
            NSManagedObject * object = [self valueForKey:rel];
            if (object && ![[object valueForKey:@"objectId"] isEqualToString:@""])
                [dic setObject:[object valueForKey:@"objectId"] forKey:rel];
            else
                [dic setObject:[NSNull null] forKey:rel];
        }
    }
    return dic;
}

- (void)updateDate
{
    [self setUpdatedAt:[NSDate date]];
}

@end
