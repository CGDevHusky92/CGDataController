/**
 *  CGDataController.h
 *  CGDataController
 *
 *  Created by Charles Gorectke on 9/27/13.
 *  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
 *
 *  The MIT License (MIT)
 *
 *  Copyright (c) 2014 Revision Works, LLC
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 *
 *  Last updated on 5/29/14
 *
 *  CGDataController is designed to do <#@"description"#>
 */

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import <CGDataController/NSManagedObject+SYNC.h>

//! Project version number for CGDataController.
FOUNDATION_EXPORT double CGDataControllerVersionNumber;

//! Project version string for CGDataController.
FOUNDATION_EXPORT const unsigned char CGDataControllerVersionString[];

typedef NS_ENUM(NSInteger, CGDSyncStatus) {
    kCGStableSyncStatus,
    kCGPendingSyncStatus,
    kCGSyncingSyncStatus
};

extern NSString * const kCGDataControllerFinishedSaveNotification;
extern NSString * const kCGDataControllerFinishedBackgroundSaveNotification;

@interface CGDataController : NSObject

+ (instancetype)initSharedDataWithStoreName:(NSString *)name;
+ (instancetype)sharedData;

- (NSManagedObjectContext *)backgroundManagedObjectContext;

/* Context Saves */
- (void)saveMasterContext;
- (void)save;

/* Storage Delete and Resets */
- (void)resetStore;
- (void)deleteStore;

/* Generate New Object With Class */
- (NSManagedObject *)newManagedObjectForClass:(NSString *)className;

/* Generate Status Dictionary */
- (NSDictionary *)statusDictionaryForClass:(NSString *)className;

/* Single Object Existence */
- (BOOL)objectExistsOnDiskWithClass:(NSString *)className andObjectId:(NSString *)objId;

/* Single Managed Object Fetch */
- (NSManagedObject *)managedObjectWithManagedID:(NSManagedObjectID *)objID;
- (NSManagedObject *)managedObjectForClass:(NSString *)className withId:(NSString *)objId;
- (NSManagedObject *)nth:(NSUInteger)num managedObjectForClass:(NSString *)className;

/* Single Dictionary Fetch */
- (NSDictionary *)managedObjAsDictionaryWithManagedID:(NSManagedObjectID *)objID;
- (NSDictionary *)managedObjAsDictionaryForClass:(NSString *)className withId:(NSString *)objId;

/* Fetch Objects */
- (NSArray *)managedObjectsForClass:(NSString *)className;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate;

/* Fetch Objects as Dictionaries for quick lookup */
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate;

#pragma mark - Object Helper Methods

- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;

@end