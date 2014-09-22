//
//  PropertyTest.h
//  CoreDataTester
//
//  Created by Charles Gorectke on 9/16/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PropertyTest : NSManagedObject

@property (nonatomic, retain) NSDate * testDate;
@property (nonatomic, retain) NSNumber * testNum;
@property (nonatomic, retain) NSNumber * testFloat;
@property (nonatomic, retain) NSString * testString;
@property (nonatomic, retain) NSNumber * testBool;

@end
