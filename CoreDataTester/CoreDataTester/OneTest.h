//
//  OneTest.h
//  CoreDataTester
//
//  Created by Charles Gorectke on 9/16/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Test;

@interface OneTest : NSManagedObject

@property (nonatomic, retain) NSDate * birthdate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Test *test;

@end
