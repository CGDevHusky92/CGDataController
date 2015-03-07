//
//  NSManagedObject+PROPS.swift
//  CGDataController
//
//  Created by Chase Gorectke on 3/5/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import CoreData

public class CGManagedObject: NSManagedObject {
    
    @NSManaged public var createdAt: NSDate
    @NSManaged public var note: String?
    @NSManaged public var objectId: String
    @NSManaged public var wasDeleted: NSNumber
    @NSManaged public var syncStatus: NSNumber
    @NSManaged public var updatedAt: NSDate
    
    class public func entityName() -> String {
        let fullClassName: String = NSStringFromClass(object_getClass(self))
        let classNameComponents: [String] = split(fullClassName) { $0 == "." }
        return last(classNameComponents)!
    }
    
    class func classString() -> String {
        return NSStringFromClass(object_getClass(self))
    }

    
    public func updateFromJSONString(jsonString: String) {
        println("Update from JSON string")
    }
    
    public func convertToJSONString() -> String {
        println("Convert to JSON string")
        return ""
    }

}
