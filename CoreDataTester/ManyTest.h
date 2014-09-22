//
//  ManyTest.h
//  CoreDataTester
//
//  Created by Charles Gorectke on 9/16/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Test;

@interface ManyTest : NSManagedObject

@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *test;
@end

@interface ManyTest (CoreDataGeneratedAccessors)

- (void)addTestObject:(Test *)value;
- (void)removeTestObject:(Test *)value;
- (void)addTest:(NSSet *)values;
- (void)removeTest:(NSSet *)values;

@end
