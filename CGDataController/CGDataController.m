/**
 *  CGDataController.m
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
 *  Last updated on 8/7/14
 */

#import "CGDataController.h"

//typedef NS_ENUM(NSString, CGDataExceptionNames) {
//    kCGDataStoreNameException=@""
//};

NSString * const kCGDataControllerFinishedSaveNotification = @"kCGDataControllerFinishedSaveNotification";
NSString * const kCGDataControllerFinishedBackgroundSaveNotification = @"kCGDataControllerFinishedBackgroundSaveNotification";

NSString * const kCGDataInitException = @"CGDataInitException";
NSString * const kCGDataStoreNameException = @"CGDataStoreNameException";
NSString * const kCGDataSaveFailedException = @"CGDataSaveFailedException";
NSString * const kCGDataNoCoordinatorException = @"CGDataNoCoordinatorException";
NSString * const kCGDataNoModelException = @"CGDataNoModelException";
NSString * const kCGDataNilParameterException = @"CGDataNilParameterException";
NSString * const kCGDataFetchFailedException = @"CGDataFetchFailedException";
NSString * const kCGDataCreateObjectFailedException = @"CGDataCreateObjectFailedException";
NSString * const kCGDataFatalErrorException = @"CGDataFatalErrorException";

@interface CGDataController ()

@property (strong, nonatomic) NSManagedObjectContext * masterManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext * backgroundManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel * managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;

@property (strong, nonatomic) NSString * storeName;
@property (strong, nonatomic) NSDateFormatter * formatter;

- (instancetype)initWithStoreName:(NSString *)name;

- (NSURL *)applicationDocumentsDirectory;
- (NSManagedObjectContext *)masterManagedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (NSArray *)objectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate asDictionaries:(BOOL)dictionaries;

@end

@implementation CGDataController
@synthesize masterManagedObjectContext=_masterManagedObjectContext;
@synthesize backgroundManagedObjectContext=_backgroundManagedObjectContext;
@synthesize managedObjectModel=_managedObjectModel;
@synthesize persistentStoreCoordinator=_persistentStoreCoordinator;

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
        NSString * reason = @"You must set a store name by calling +(id)initSharedDataWithStoreName: before making calls to +(id)sharedData";
        @throw [NSException exceptionWithName:@"CGDataStoreNameException" reason:reason userInfo:nil];
    });
    return sharedData;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"CGDataInitException" reason:@"init should not be called directly" userInfo:nil];
}

- (instancetype)initWithStoreName:(NSString *)name
{
    self = [super init];
    if (self) {
        _storeName = name;
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:nil queue:nil usingBlock:^(NSNotification * note) {
            NSManagedObjectContext * moc = _masterManagedObjectContext;
            if (note.object != moc) {
                [moc performBlock:^(){
                    [moc mergeChangesFromContextDidSaveNotification:note];
                }];
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)masterManagedObjectContext
{
    if (_masterManagedObjectContext) return _masterManagedObjectContext;
    _masterManagedObjectContext = [self setupManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
    return _masterManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext) return _backgroundManagedObjectContext;
    _backgroundManagedObjectContext = [self setupManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType];
    return _backgroundManagedObjectContext;
}

- (NSManagedObjectContext *)setupManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    NSManagedObjectContext * managedObjectContext;
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
        [managedObjectContext performBlockAndWait:^{
            [managedObjectContext setPersistentStoreCoordinator:coordinator];
        }];
        return managedObjectContext;
    } else {
        @throw [NSException exceptionWithName:kCGDataNoCoordinatorException reason:@"Coordinator not found." userInfo:nil];
    }
}

- (void)saveMasterContext
{
    [self.masterManagedObjectContext performBlockAndWait:^{
        NSError * error;
        BOOL saved = [self.masterManagedObjectContext save:&error];
        if (!saved) @throw [NSException exceptionWithName:kCGDataSaveFailedException reason:[error localizedDescription] userInfo:[error userInfo]];
    }];
}

- (void)save
{
    [self.backgroundManagedObjectContext performBlockAndWait:^{
        NSError * error;
        BOOL saved = [self.backgroundManagedObjectContext save:&error];
        if (!saved) @throw [NSException exceptionWithName:kCGDataSaveFailedException reason:[error localizedDescription] userInfo:[error userInfo]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kCGDataControllerFinishedSaveNotification object:nil];
    }];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator)
        return _persistentStoreCoordinator;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", _storeName]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSManagedObjectModel *model = [self managedObjectModel];
    if (model) {
        NSError *error;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            @throw [NSException exceptionWithName:kCGDataNoCoordinatorException reason:[error localizedDescription] userInfo:[error userInfo]];
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel)
        return _managedObjectModel;
    _managedObjectModel = [self modifiedObjectModel];
    return _managedObjectModel;
}

- (NSManagedObjectModel *)modifiedObjectModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_storeName withExtension:@"mom"];
    if (!modelURL) {
        modelURL = [[NSBundle mainBundle] URLForResource:_storeName withExtension:@"momd"];
    }
    
    if (modelURL) {
        NSManagedObjectModel *modifiableModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSMutableArray *entities = [NSMutableArray array];
        for (NSEntityDescription *ent in [modifiableModel entities]) {
            NSMutableArray *currentProps = [[ent properties] mutableCopy];
            
            NSAttributeDescription *objId = [[NSAttributeDescription alloc] init];
            [objId setName:@"objectId"];
            [objId setAttributeType:NSStringAttributeType];
            [objId setOptional:NO];
            [currentProps addObject:objId];
            
            NSAttributeDescription *createdAt = [[NSAttributeDescription alloc] init];
            [createdAt setName:@"createdAt"];
            [createdAt setAttributeType:NSDateAttributeType];
            [createdAt setOptional:NO];
            [currentProps addObject:createdAt];
            
            NSAttributeDescription *updatedAt = [[NSAttributeDescription alloc] init];
            [updatedAt setName:@"updatedAt"];
            [updatedAt setAttributeType:NSDateAttributeType];
            [updatedAt setOptional:NO];
            [currentProps addObject:updatedAt];
            
            NSAttributeDescription *wasDeleted = [[NSAttributeDescription alloc] init];
            [wasDeleted setName:@"wasDeleted"];
            [wasDeleted setAttributeType:NSBooleanAttributeType];
            [wasDeleted setOptional:NO];
            [wasDeleted setDefaultValue:[NSNumber numberWithBool:NO]];
            [currentProps addObject:wasDeleted];
            
            NSAttributeDescription *note = [[NSAttributeDescription alloc] init];
            [note setName:@"note"];
            [note setAttributeType:NSStringAttributeType];
            [note setOptional:YES];
            [currentProps addObject:note];
            
            NSAttributeDescription *syncStatus = [[NSAttributeDescription alloc] init];
            [syncStatus setName:@"syncStatus"];
            [syncStatus setAttributeType:NSInteger16AttributeType];
            [syncStatus setOptional:NO];
            [currentProps addObject:syncStatus];
            
            [ent setProperties:currentProps];
            [entities addObject:ent];
        }
        [modifiableModel setEntities:entities];
        
        return modifiableModel;
    } else {
        @throw [NSException exceptionWithName:kCGDataNoModelException reason:@"Model could not be found in resources." userInfo:nil];
    }
}

- (void)resetStore
{
    [self save];
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
        NSError * error;
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        if (!error) {
            for (NSManagedObject *ct in [_masterManagedObjectContext registeredObjects]) {
                [_masterManagedObjectContext deleteObject:ct];
            }
        } else {
            @throw [NSException exceptionWithName:kCGDataFatalErrorException reason:[error localizedDescription] userInfo:[error userInfo]];
        }
    }
    _persistentStoreCoordinator = nil;
    [self persistentStoreCoordinator];
}

#pragma mark - Generate Status Dictionary

- (NSDictionary *)statusDictionaryForClass:(NSString *)className
{
    NSError * error;
    NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:className];
    int count = (int)[[self backgroundManagedObjectContext] countForFetchRequest:request error:&error];
    if (error) {
        @throw [NSException exceptionWithName:kCGDataFetchFailedException reason:[error localizedDescription] userInfo:[error userInfo]];
    } else {
        NSMutableDictionary * ret = [[NSMutableDictionary alloc] init];
        NSArray * dateObj = [self managedObjectsForClass:className sortedByKey:@"updatedAt" ascending:NO withFetchLimit:1];
        if ([dateObj count] > 1) {
            @throw [NSException exceptionWithName:kCGDataFatalErrorException reason:@"Fetch for 1 item returned multiple" userInfo:nil];
        } else if ([dateObj count] == 0) {
            [ret setObject:[NSNumber numberWithInt:count] forKey:@"count"];
            [ret setObject:@"" forKey:@"lastUpdatedAt"];
        } else {
            NSManagedObject * obj = [dateObj objectAtIndex:0];
            [ret setObject:[NSNumber numberWithInt:count] forKey:@"count"];
            [ret setObject:[obj updatedAt] forKey:@"lastUpdatedAt"];
        }
        return ret;
    }
}

#pragma mark - Requests For Specific Object

- (NSManagedObject *)newManagedObjectForClass:(NSString *)className
{
    if (!className) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"Class name is nil." userInfo:nil];
    NSManagedObjectContext *context = [self backgroundManagedObjectContext];
    NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:context];
    if (!obj) @throw [NSException exceptionWithName:kCGDataCreateObjectFailedException reason:[NSString stringWithFormat:@"Could not create object for class <%@>", className] userInfo:nil];
    
    NSDate *date = [NSDate date];
//    NSDateFormatter *formatter = [self dateFormatter];
    [obj setCreatedAt:date]; // [formatter stringFromDate:date]];
    [obj setUpdatedAt:date]; // [formatter stringFromDate:date]];
    [obj setObjectId:[[NSUUID UUID] UUIDString]];
    [obj setSyncStatus:@(kCGPendingSyncStatus)];
    return obj;
}

- (BOOL)objectExistsOnDiskWithClass:(NSString *)className andObjectId:(NSString *)objId
{
    NSManagedObject * obj = [self managedObjectForClass:className withId:objId];
    if (obj) return YES;
    else return NO;
}

#pragma mark - Fetch Request For Specific Object

- (NSManagedObject *)managedObjectWithManagedID:(NSManagedObjectID *)objID
{
    if (!objID) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"NSManagedObjectID is nil." userInfo:nil];
    return [[self backgroundManagedObjectContext] objectRegisteredForID:objID];
}

- (NSManagedObject *)managedObjectForClass:(NSString *)className withId:(NSString *)objId
{
    if (!className || !objId) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"Class name or objectId is nil." userInfo:nil];
    NSArray * objArray = [self managedObjectsForClass:className sortedByKey:@"createdAt" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"objectId like %@", objId]];
    if (!objArray || [objArray count] == 0) return nil;
    if ([objArray count] > 1) @throw [NSException exceptionWithName:kCGDataFatalErrorException reason:@"More than one object has that objectId." userInfo:nil];
    return [objArray objectAtIndex:0];
}

- (NSManagedObject *)nth:(NSUInteger)num managedObjectForClass:(NSString *)className
{
    if (!className) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"Class name is nil." userInfo:nil];
    NSArray * objArray = [self managedObjectsForClass:className sortedByKey:@"updatedAt" ascending:NO];
    if (objArray && [objArray count] >= num)
        return [objArray objectAtIndex:(num - 1)];
    return nil;
}

#pragma mark - Fetch Request For Specific Dictionary

- (NSDictionary *)managedObjAsDictionaryWithManagedID:(NSManagedObjectID *)objID
{
    if (!objID) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"NSManagedObjectID is nil." userInfo:nil];
    NSManagedObject * manObj = [[self backgroundManagedObjectContext] objectRegisteredForID:objID];
    return [self managedObjAsDictionaryForClass:[[manObj entity] managedObjectClassName] withId:[manObj objectId]];
}

- (NSDictionary *)managedObjAsDictionaryForClass:(NSString *)className withId:(NSString *)objId
{
    if (!className || !objId) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"Class name or objectId is nil." userInfo:nil];
    NSArray *objArray = [self managedObjsAsDictionariesForClass:className sortedByKey:@"createdAt" ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"objectId like %@", objId]];
    if (!objArray) return nil;
    if ([objArray count] > 1 || [objArray count] == 0) @throw [NSException exceptionWithName:kCGDataFatalErrorException reason:@"More than one object has that objectId." userInfo:nil];
    return [objArray objectAtIndex:0];
}

#pragma mark - Fetch Requests For Objects

- (NSArray *)managedObjectsForClass:(NSString *)className
{
    return [self managedObjectsForClass:className sortedByKey:nil ascending:YES];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:0 withBatchSize:0 withPredicate:nil];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withPredicate:nil];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withBatchSize:num withPredicate:nil];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withPredicate:(NSPredicate *)predicate
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:0 withBatchSize:0 withPredicate:predicate];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withBatchSize:num withPredicate:nil];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withPredicate:(NSPredicate *)predicate
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withBatchSize:0 withPredicate:predicate];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate
{
    return [self managedObjectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:0 withBatchSize:num withPredicate:predicate];
}

- (NSArray *)managedObjectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate
{
    return [self objectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withBatchSize:num withPredicate:predicate asDictionaries:NO];
}

#pragma mark - Fetch Requests For Dictionaries

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:nil ascending:YES];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withFetchLimit:0 withBatchSize:0 withPredicate:nil];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withPredicate:nil];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withBatchSize:num withPredicate:nil];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withPredicate:(NSPredicate *)predicate
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withFetchLimit:0 withBatchSize:0 withPredicate:predicate];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withBatchSize:num withPredicate:nil];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withPredicate:(NSPredicate *)predicate
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withBatchSize:0 withPredicate:predicate];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate
{
    return [self managedObjsAsDictionariesForClass:className sortedByKey:key ascending:ascend withFetchLimit:0 withBatchSize:num withPredicate:predicate];
}

- (NSArray *)managedObjsAsDictionariesForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate
{
    return [self objectsForClass:className sortedByKey:key ascending:ascend withFetchLimit:limit withBatchSize:num withPredicate:predicate asDictionaries:YES];
}

#pragma mark - Fetch Objects Top Method

- (NSArray *)objectsForClass:(NSString *)className sortedByKey:(NSString *)key ascending:(BOOL)ascend withFetchLimit:(NSUInteger)limit withBatchSize:(NSUInteger)num withPredicate:(NSPredicate *)predicate asDictionaries:(BOOL)dictionaries
{
    if (!className) @throw [NSException exceptionWithName:kCGDataNilParameterException reason:@"Class name was nil." userInfo:nil];
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[CGDataController sharedData] backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    
    [fetchRequest setFetchBatchSize:num];
    if (limit > 0) [fetchRequest setFetchLimit:limit];
    if (key) [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascend]]];
    if (predicate) [fetchRequest setPredicate:predicate];
    if (dictionaries) [fetchRequest setResultType:NSDictionaryResultType];
    
    [managedObjectContext performBlockAndWait:^{
        NSError * error;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error) @throw [NSException exceptionWithName:kCGDataFetchFailedException reason:[error localizedDescription] userInfo:[error userInfo]];
    }];
    return results;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Date Conversion Methods

static NSDateFormatter * dateFormatter = nil;

- (NSDateFormatter *)dateFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    });
    return dateFormatter;
}

- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString {
    // NSDateFormatter does not like ISO 8601 so strip the milliseconds and timezone
    //    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
    return [self.dateFormatter dateFromString:dateString];
}

- (NSString *)dateStringForAPIUsingDate:(NSDate *)date {
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    //    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-1)];
    return dateString;
}

@end