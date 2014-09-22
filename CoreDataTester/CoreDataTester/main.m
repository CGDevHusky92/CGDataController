//
//  main.m
//  CoreDataTester
//
//  Created by Charles Gorectke on 9/16/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CGDataController.h"
#import "NSManagedObject+SYNC.h"

#import "Test.h"
#import "OneTest.h"
#import "SubTest.h"
#import "ManyTest.h"
#import "OneManyTest.h"
#import "PropertyTest.h"


#define REL_TEST_ONE        0
#define REL_TEST_MANY       0
#define REL_TEST_ONE_MANY   0
#define REL_TEST_MANY_ONE   0
#define PROP_TEST           1


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"Starting Core Data Testing");
        
        [CGDataController initSharedDataWithStoreName:@"Tester"];
        
#if REL_TEST_ONE || REL_TEST_MANY || REL_TEST_ONE_MANY || REL_TEST_MANY_ONE
        Test * testItem = (Test *)[[CGDataController sharedData] newManagedObjectForClass:@"Test"];
        
        [testItem setName:@"Test"];
        [testItem setBirthdate:[NSDate date]];
        
        for (int i = 0; i < 3; i++) {
            SubTest * subTest = (SubTest *)[[CGDataController sharedData] newManagedObjectForClass:@"SubTest"];
            
            [subTest setName:[NSString stringWithFormat:@"SubTest%d", i + 1]];
            [subTest setBirthdate:[NSDate date]];
            
            [subTest setTest:testItem];
            [testItem addSubTestsObject:subTest];
            
            ManyTest * manyTest = (ManyTest *)[[CGDataController sharedData] newManagedObjectForClass:@"ManyTest"];
            
            [manyTest setName:[NSString stringWithFormat:@"ManyTest%d", i + 1]];
            [manyTest setBirthdate:[NSDate date]];
            
            [manyTest addTestObject:testItem];
            [testItem addManyTestsObject:manyTest];
        }
        
        [[CGDataController sharedData] save];

        NSLog(@"Test Item: %@", testItem);
        
        NSMutableDictionary * testProps = [[testItem dictionaryFromObject] mutableCopy];
#endif
        
#if REL_TEST_ONE_MANY
        /* One To Many Test */
        
        SubTest * subTest = (SubTest *)[[CGDataController sharedData] newManagedObjectForClass:@"SubTest"];
        
        [subTest setName:@"SubTestFinal"];
        [subTest setBirthdate:[NSDate date]];
        
        [[CGDataController sharedData] save];
        
        
        [testProps setValue:@"Chase" forKey:@"name"];
        
        NSMutableArray * subArray = [[testProps valueForKey:@"subTests"] mutableCopy];
        [subArray addObject:[subTest objectId]];
        
        [testProps setValue:subArray forKey:@"subTests"];
        
//        NSLog(@"Updated Many Test Props: %@", testProps);
        
        [testItem updateFromDictionary:testProps];
        
        [[CGDataController sharedData] save];
        
        NSLog(@"Updated Many Test Item: %@", testItem);
#endif
        
#if REL_TEST_ONE
        /* One To One Test */
        
        OneTest * oneTest = (OneTest *)[[CGDataController sharedData] newManagedObjectForClass:@"OneTest"];
        
        [oneTest setName:@"OneTest"];
        [oneTest setBirthdate:[NSDate date]];
        
        [[CGDataController sharedData] save];
        
        [testProps setValue:[oneTest objectId] forKey:@"oneTest"];
        
//        NSLog(@"Updated One Test Props: %@", testProps);
        
        [testItem updateFromDictionary:testProps];
        
        [[CGDataController sharedData] save];
        
        NSLog(@"Updated One Test Item: %@", testItem);
#endif
        
#if REL_TEST_MANY
        /* Many to Many Test */
        
        ManyTest * manyTest = (ManyTest *)[[CGDataController sharedData] newManagedObjectForClass:@"ManyTest"];
        
        [manyTest setName:@"ManyTest"];
        [manyTest setBirthdate:[NSDate date]];
        
        [[CGDataController sharedData] save];
        
        NSMutableArray * manyArray = [[testProps valueForKey:@"manyTests"] mutableCopy];
        [manyArray addObject:[manyTest objectId]];
        
        [testProps setValue:manyArray forKey:@"manyTests"];
        
//        NSLog(@"Updated Many Many Test Props: %@", testProps);
        
        [testItem updateFromDictionary:testProps];
        
        [[CGDataController sharedData] save];
        
        NSLog(@"Updated Many Many Test Item: %@", testItem);
#endif
        
#if REL_TEST_MANY_ONE
        /* Many To One Test */
        
        OneManyTest * oneManyTest = (OneManyTest *)[[CGDataController sharedData] newManagedObjectForClass:@"OneManyTest"];
        
        [oneManyTest setName:@"OneManyTest"];
        [oneManyTest setBirthdate:[NSDate date]];
        
        [[CGDataController sharedData] save];
        
        [testProps setValue:[oneManyTest objectId] forKey:@"oneManyTest"];
        
//        NSLog(@"Updated Many One Test Props: %@", testProps);
        
        [testItem updateFromDictionary:testProps];
        
        [[CGDataController sharedData] save];
        
        NSLog(@"Updated Many One Test Item: %@", testItem);
#endif
        
#if PROP_TEST
        /* Property Test */
        
        PropertyTest * propTest = (PropertyTest *)[[CGDataController sharedData] newManagedObjectForClass:@"PropertyTest"];
        
        [[CGDataController sharedData] save];
        
        NSMutableDictionary * updateDic = [[NSMutableDictionary alloc] init];
        [updateDic setValue:[NSNumber numberWithBool:YES] forKey:@"testBool"];
        [updateDic setValue:[NSDate date] forKey:@"testDate"];
        [updateDic setValue:[NSNumber numberWithFloat:1.23] forKey:@"testFloat"];
        [updateDic setValue:[NSNumber numberWithInt:3] forKey:@"testNum"];
        [updateDic setValue:@"Yay String" forKey:@"testString"];
        
        [propTest updateFromDictionary:updateDic];
        
        [[CGDataController sharedData] save];
        
        NSLog(@"Updated propTest: %@", propTest);
#endif
    }
    return 0;
}
