//
//  DataController.h
//  ThisOrThat
//
//  Created by Charles Gorectke (Revision Works, LLC) on 9/27/13.
//  Copyright Revision Works 2013
//  Engineering A Better World
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

typedef enum CGSyncStatus
{
    kCGSyncStable = 1,
    kCGSyncPending,
    kCGSyncSyncing
} CGSyncStatus;

@interface CGDataController : NSObject

+ (instancetype)initSharedDataWithStoreName:(NSString *)name;
+ (instancetype)sharedData;
- (NSManagedObjectContext *)backgroundManagedObjectContext;

- (void)saveMasterContext;
- (void)saveBackgroundContext;

- (void)resetStore;
- (void)deleteStore;

/* Fetch Object */
- (NSManagedObject *)newManagedObjectForClass:(NSString *)className;
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