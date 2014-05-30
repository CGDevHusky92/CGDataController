/**
 *  NSManagedObject+SYNC.h
 *  CGDataController
 *
 *  Created by Charles Gorectke on 2/23/14.
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

@interface NSManagedObject (SYNC)

@property (nonatomic, retain) NSString *className;
@property (nonatomic, retain) NSDate *createdAt;
@property (nonatomic, retain) NSString *objectId;
@property (nonatomic, retain) NSDate *updatedAt;
@property (nonatomic, retain) NSNumber *syncStatus;

- (BOOL)updateFromDictionary:(NSDictionary *)dic;
- (NSDictionary *)dictionaryFromObject;
- (NSDictionary *)cleanDictionary:(NSDictionary *)dic;

@end
