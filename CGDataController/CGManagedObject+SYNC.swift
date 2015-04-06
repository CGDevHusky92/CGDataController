//
//  NSManagedObject+SYNC.swift
//  CGDataController
//
//  Created by Chase Gorectke on 2/28/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import CoreData

public extension CGManagedObject {
    
    /* Public Methods */
    
    
    public func functionDoesStuff() {
        println("I work")
    }
    
//    class Person: NSManagedObject {
//        convenience init(context: NSManagedObjectContext) {
//            let entityDescription = NSEntityDescription.entityForName("Person", inManagedObjectContext: context)!
//            self.init(entity: entityDescription, insertIntoManagedObjectContext: context)
//        }
//    }
    
//    extension NSManagedObject {
//        class public func entityName() -> String {
//            let fullClassName: String = NSStringFromClass(object_getClass(self))
//            let classNameComponents: [String] = split(fullClassName) { $0 == "." }
//            return last(classNameComponents)!
//        }
//        class public func insertNewObjectInContext(context: NSManagedObjectContext) -> AnyObject {
//            return NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: context)
//        }
//    }
    
    func updateFromDictionary(dictionary: [ String : AnyObject? ]) -> Bool {
        return false
    }
    
    func dictionaryFromObject() -> [ String : AnyObject? ] {
        let dic = CGDataController.sharedData().managedObjAsDictionaryWithManagedID(self.objectID)
        
        
        
        println("\(dic)")
        
        return [String : AnyObject? ]()
    }
    
    func deleteObjectAndRelationships() {
        
    }
    
    func updateDate() {
        self.updatedAt = NSDate()
    }
    
    /* Private Methods */
    
//    - (void)updateAttributesFromDictionary:(NSDictionary *)dictionary
//    - (BOOL)updateRelationshipsFromDictionary:(NSDictionary *)dictionary
//    - (void)fireSelector:(SEL)select onObject:(id)object withParameter:(id)param
//    - (NSMutableDictionary *)convertDatesToStrings:(NSMutableDictionary *)dictionary
//    - (NSDictionary *)relationshipDictionaryFromObject
}

