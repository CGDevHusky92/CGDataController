//
//  DataController.m
//  ThisOrThat
//
//  Created by Charles Gorectke (Revision Works, LLC) on 9/27/13.
//  Copyright Revision Works 2013
//  Engineering A Better World
//

#import "CGDataController.h"

@interface CGDataController()

@property (nonatomic, strong) NSManagedObjectContext *masterManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundManagedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSString *storeName;

- (instancetype)initWithStoreName:(NSString *)name;

- (NSManagedObjectContext *)masterManagedObjectContext;
- (NSManagedObjectContext *)newManagedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;

@end

@implementation CGDataController
@synthesize masterManagedObjectContext = _masterManagedObjectContext;
@synthesize backgroundManagedObjectContext = _backgroundManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

static dispatch_once_t once;
static CGDataController *sharedData;

+ (instancetype)initSharedDataWithStoreName:(NSString *)name
{
    dispatch_once(&once, ^{
        sharedData = [[self alloc] initWithStoreName:name];
    });
    return sharedData;
}

+ (instancetype)sharedData
{
    dispatch_once(&once, ^{
        sharedData = [[self alloc] init];
    });
    return sharedData;
}

- (instancetype)initWithStoreName:(NSString *)name
{
    self = [super init];
    if (self) {
        _storeName = name;
    }
    return self;
}

#pragma mark - Core Data stack

// Used to propegate saves to the persistent store (disk) without blocking the UI
- (NSManagedObjectContext *)masterManagedObjectContext
{
    if (_masterManagedObjectContext != nil) {
        return _masterManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_masterManagedObjectContext performBlockAndWait:^{
            [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];
        }];
    }
    
    return _masterManagedObjectContext;
}

// Return the NSManagedObjectContext to be used in the background during sync
- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext != nil) {
        return _backgroundManagedObjectContext;
    }
    
    NSManagedObjectContext *masterContext = [self masterManagedObjectContext];
    if (masterContext != nil) {
        _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundManagedObjectContext performBlockAndWait:^{
            [_backgroundManagedObjectContext setParentContext:masterContext]; 
        }];
    }
    
    return _backgroundManagedObjectContext;
}

// Return a new NSManagedObjectContext
- (NSManagedObjectContext *)newManagedObjectContext
{
    NSManagedObjectContext *newContext = nil;
    NSManagedObjectContext *masterContext = [self masterManagedObjectContext];
    if (masterContext != nil) {
        newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [newContext performBlockAndWait:^{
            [newContext setParentContext:masterContext]; 
        }];
    }
    return newContext;
}

- (void)saveMasterContext
{
    [self.masterManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [self.masterManagedObjectContext save:&error];
        if (!saved) {
            // do some real error handling
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
}

- (void)saveBackgroundContext
{
    [self.backgroundManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [self.backgroundManagedObjectContext save:&error];
        if (!saved) {
            // do some real error handling
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
}

- (void)performFullSaveOnMainThread
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveBackgroundContext];
        [self saveMasterContext];
    });
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_storeName withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    // ThisOrThat Hack
#ifdef THISORTHAT_HACK
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"ModelUpdate1.2.0"] || ![[defaults objectForKey:@"ModelUpdate1.2.0"] boolValue]) {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"ModelUpdate1.2.0"];
        [defaults synchronize];
        [self deleteStore];
    }
#endif
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", _storeName]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSManagedObjectModel *model = [self managedObjectModel];
    if (model) {
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            NSLog(@"Error: %@ - %@", error, [error userInfo]);
        }
    } else {
        NSLog(@"Error: ManagedObjectModel is nil");
    }
    
    return _persistentStoreCoordinator;
}

- (void)resetStore
{
    NSError *error = nil;
    [self saveBackgroundContext];
    if (error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    [self saveMasterContext];
    _backgroundManagedObjectContext = nil;
    _masterManagedObjectContext = nil;
    _managedObjectModel = nil;
    _persistentStoreCoordinator = nil;
}

- (void)deleteStore
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", _storeName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        for (NSManagedObject *ct in [_masterManagedObjectContext registeredObjects]) {
            [_masterManagedObjectContext deleteObject:ct];
        }
    }
    
    _persistentStoreCoordinator = nil;
    [self persistentStoreCoordinator];
}

#pragma mark - Requests For Specific Object

- (BOOL)objectExistsOnDisk:(NSString *)objId
{
#warning Implement
    return NO;
}

- (NSManagedObject *)newManagedObjectForClass:(NSString *)className
{
    NSManagedObjectContext *context = [self backgroundManagedObjectContext];
    NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:context];
    
    if (!obj) {
        NSLog(@"Error: Could not create object for class <%@>", className);
    }
    
    return obj;
}

- (NSManagedObject *)managedObjectForClass:(NSString *)className withId:(NSString *)objId
{
    if (!className || !objId) return nil;
    
    NSArray *objArray = [self managedObjectsForClass:className sortedByKey:@"createdAt" withPredicate:[NSPredicate predicateWithFormat:@"objectId like %@", objId]];
    
    if ([objArray count] != 1) {
        NSLog(@"Error: More then one object for objectId <%@>", objId);
        return nil;
    }
    
    return [objArray objectAtIndex:0];
}

#pragma mark - Fetch Requests For Objects

- (NSArray *)managedObjectsForClass:(NSString *)className
{
    return [self managedObjectsForClass:className sortedByKey:nil];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key {
    return [self managedObjectsForClass:className sortedByKey:key withBatchSize:0];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num
{
    return [self managedObjectsForClass:className sortedByKey:key withBatchSize:num withPredicate:nil];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend
{
    return [self managedObjectsForClass:className sortedByKey:key withPredicate:nil ascending:ascend];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate
{
    return [self managedObjectsForClass:className sortedByKey:key withPredicate:predicate ascending:NO];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend
{
    return [self managedObjectsForClass:className sortedByKey:key withBatchSize:0 withPredicate:predicate ascending:ascend];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num ascending:(BOOL)ascend
{
    return [self managedObjectsForClass:className sortedByKey:key withBatchSize:num withPredicate:nil ascending:ascend];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate
{
    return [self managedObjectsForClass:className sortedByKey:key withBatchSize:num withPredicate:predicate ascending:NO];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend
{
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[CGDataController sharedData] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    [fetchRequest setFetchBatchSize:num];
    
    if (key) {
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascend]]];
    }
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}

#pragma mark - Fetch Requests For Dictionaries

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:nil];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key {
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withBatchSize:0];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withBatchSize:num withPredicate:nil];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withPredicate:nil ascending:ascend];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withPredicate:predicate ascending:NO];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withBatchSize:0 withPredicate:predicate ascending:ascend];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num ascending:(BOOL)ascend
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withBatchSize:num withPredicate:nil ascending:ascend];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key withBatchSize:num withPredicate:predicate ascending:NO];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key withBatchSize:(int)num withPredicate:(NSPredicate *)predicate ascending:(BOOL)ascend
{
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[CGDataController sharedData] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    [fetchRequest setFetchBatchSize:num];
    [fetchRequest setResultType:NSDictionaryResultType];
    
    if (key) {
        [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascend]]];
    }
    
    if (predicate) {
        [fetchRequest setPredicate:predicate];
    }
    
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return results;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end