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

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "NSManagedObject+SYNC.h"

typedef enum CGSyncStatus
{
    kCGStableSyncStatus = 1,
    kCGPendingSyncStatus,
    kCGSyncingSyncStatus
} CGSyncStatus;

@interface CGDataController : NSObject

+ (instancetype)initSharedDataWithStoreName:(NSString *)name;
+ (instancetype)sharedData;
- (NSManagedObjectContext *)backgroundManagedObjectContext;

/* Context Saves */
- (void)saveMasterContext;
- (void)saveBackgroundContext;
- (void)performFullSaveOnMainThread;

/* Storage Delete and Resets */
- (void)resetStore;
- (void)deleteStore;

/* Unique ID Generation */
- (NSString *)generateUniqueID;

/* Generate New Object With Class */
- (NSManagedObject *)newManagedObjectForClass:(NSString *)className;

/* Single Object Existence and Fetch */
- (BOOL)objectExistsOnDiskWithClass:(NSString *)className andObjectId:(NSString *)objId;
- (NSManagedObject *)managedObjectForClass:(NSString *)className withId:(NSString *)objId;

/* Fetch Objects */
- (NSArray *)managedObjectsForClass:(NSString *)className;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num ascending:(BOOL)ascend;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend;

/* Fetch Objects as Dictionaries for quick lookup */
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num ascending:(BOOL)ascend;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate;
- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend;

@end