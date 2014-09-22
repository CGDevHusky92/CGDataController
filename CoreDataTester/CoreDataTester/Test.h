//
//  Test.h
//  CoreDataTester
//
//  Created by Charles Gorectke on 9/16/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ManyTest, OneManyTest, OneTest, SubTest;

@interface Test : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSSet *subTests;
@property (nonatomic, retain) OneTest *oneTest;
@property (nonatomic, retain) NSSet *manyTests;
@property (nonatomic, retain) OneManyTest *oneManyTest;
@end

@interface Test (CoreDataGeneratedAccessors)

- (void)addSubTestsObject:(SubTest *)value;
- (void)removeSubTestsObject:(SubTest *)value;
- (void)addSubTests:(NSSet *)values;
- (void)removeSubTests:(NSSet *)values;

- (void)addManyTestsObject:(ManyTest *)value;
- (void)removeManyTestsObject:(ManyTest *)value;
- (void)addManyTests:(NSSet *)values;
- (void)removeManyTests:(NSSet *)values;

@end
