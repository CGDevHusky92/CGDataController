//
//  NSManagedObject+SYNC.swift
//  CGDataController
//
//  Created by Chase Gorectke on 2/28/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

/*

import CoreData

extension NSManagedObject {
    
    /* AssociatedKeys */
    private struct ak {
        static var createdAtKey = "nsm_CreatedAtKey"
        static var noteKey = "nsm_NoteKey"
        static var objectIdKey = "nsm_ObjectIdKey"
        static var wasDeletedKey = "nsm_WasDeletedKey"
        static var serverClassKey = "nsm_ServerClassKey"
        static var syncStatusKey = "nsm_SyncStatusKey"
        static var updatedAtKey = "nsm_UpdatedAtKey"
    }
    
    var createdAt: NSDate? {
        get { return objc_getAssociatedObject(self, &ak.createdAtKey) as? NSDate }
        set (d) { objc_setAssociatedObject(self, &ak.createdAtKey, d as NSDate?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }
    
    var note: NSString? {
        get { return objc_getAssociatedObject(self, &ak.noteKey) as? NSString }
        set (d) { objc_setAssociatedObject(self, &ak.noteKey, d as NSString?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }
    
    var objectId: NSString? {
        get { return objc_getAssociatedObject(self, &ak.objectIdKey) as? NSString }
        set (d) { objc_setAssociatedObject(self, &ak.objectIdKey, d as NSString?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }
    
    var wasDeleted: NSNumber? {
        get { return objc_getAssociatedObject(self, &ak.wasDeletedKey) as? NSNumber }
        set (d) { objc_setAssociatedObject(self, &ak.wasDeletedKey, d as NSNumber?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }
    
    var serverClass: NSString? {
        get { return objc_getAssociatedObject(self, &ak.serverClassKey) as? NSString }
        set (d) { objc_setAssociatedObject(self, &ak.serverClassKey, d as NSString?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }
    
    var syncStatus: NSNumber? {
        get { return objc_getAssociatedObject(self, &ak.syncStatusKey) as? NSNumber }
        set (d) { objc_setAssociatedObject(self, &ak.syncStatusKey, d as NSNumber?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }
    
    var updatedAt: NSDate? {
        get { return objc_getAssociatedObject(self, &ak.updatedAtKey) as? NSDate }
        set (d) { objc_setAssociatedObject(self, &ak.updatedAtKey, d as NSDate?, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC)) }
    }

    /* Public Methods */
    
    func updateFromDictionary(dictionary: [ String : AnyObject? ]) -> Bool {
        return false
    }
    
    func dictionaryFromObject() -> [ String : AnyObject? ] {
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

*/
