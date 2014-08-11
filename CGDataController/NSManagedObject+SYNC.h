//
//  NSManagedObject+SYNC.h
//  ThisOrThat
//
//  Created by Chase Gorectke on 2/23/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface NSManagedObject (SYNC)

@property (nonatomic, strong) NSDateFormatter *format;

@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * note;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * wasDeleted;
@property (nonatomic, retain) NSString * serverClass;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * updatedAt;

- (void)updateDate;
- (BOOL)updateFromDictionary:(NSDictionary *)dic;
- (NSDictionary *)dictionaryFromObject;
- (NSDictionary *)cleanDictionary:(NSDictionary *)dic;

@end
