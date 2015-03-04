/**
 *  CGDataController.swift
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
 *  Last updated on 2/22/15
 */

import UIKit
import CoreData

public let kCGDataControllerFinishedSaveNotification = "kCGDataControllerFinishedSaveNotification"
public let kCGDataControllerFinishedBackgroundSaveNotification = "kCGDataControllerFinishedBackgroundSaveNotification"

public class CGDataController: NSObject {
    
    var defaultStoreName: String?
    var dataStores: [String:CGDataStore]
    
    override init() {
        dataStores = [String:CGDataStore]()
        super.init()
    }
    
    public class var sharedDataController: CGDataController {
        struct StaticData {
            static let data : CGDataController = CGDataController()
        }
        return StaticData.data
    }
    
    public class func initSharedDataWithStoreName(storeName: String, makeDefault defaultStore: Bool = false) -> CGDataStore {
        if let defStore = CGDataController.sharedDataController.defaultStoreName {
            if defaultStore {
                CGDataController.sharedDataController.defaultStoreName = storeName
            }
        } else {
            CGDataController.sharedDataController.defaultStoreName = storeName
        }
        
        let dataStore = CGDataStore(sName: storeName)
        CGDataController.sharedDataController.dataStores.updateValue(dataStore, forKey: storeName)
        
        return dataStore
    }
    
    public class func sharedData() -> CGDataStore {
        let dataController = CGDataController.sharedDataController
        if let storeName = dataController.defaultStoreName {
            return self.sharedDataWithName(storeName)
        }
        assert(false, "You must set a store name by calling +(id)initSharedDataWithStoreName: before making calls to +(id)sharedData")
    }
    
    public class func sharedDataWithName(sName: String) -> CGDataStore {
        let dataController = CGDataController.sharedDataController
        if let dataStore = dataController.dataStores[sName] {
            return dataStore
        }
        assert(false, "You must set a store name by calling +(id)initSharedDataWithStoreName: before making calls to +(id)sharedDataWithName:")
    }
    
    public class func modifiedObjectModelWithStoreName(storeName: String) -> NSManagedObjectModel? {
        
        var modelURLTemp = NSBundle.mainBundle().URLForResource(storeName, withExtension: "mom")
        if let modelURL = modelURLTemp {} else {
            modelURLTemp = NSBundle.mainBundle().URLForResource(storeName, withExtension: "momd")
        }
        
        if let modelURL = modelURLTemp {
            let modifiableModelTemp = NSManagedObjectModel(contentsOfURL: modelURL)
            
            if let modifiableModel = modifiableModelTemp {
                var entities = [NSEntityDescription]()
                let modelEntities = modifiableModel.entities as! [NSEntityDescription]
                for ent in modelEntities {
                    var currentProps = ent.properties
                    
                    let objId = NSAttributeDescription()
                    objId.name = "objectId"
                    objId.attributeType = .StringAttributeType
                    objId.optional = false
                    objId.defaultValue = NSUUID().UUIDString
                    currentProps.append(objId)
                    
                    let createdAt = NSAttributeDescription()
                    createdAt.name = "createdAt"
                    createdAt.attributeType = .DateAttributeType
                    createdAt.optional = false
                    currentProps.append(createdAt)
                    
                    let updatedAt = NSAttributeDescription()
                    updatedAt.name = "updatedAt"
                    updatedAt.attributeType = .DateAttributeType
                    updatedAt.optional = false
                    currentProps.append(updatedAt)
                    
                    let wasDeleted = NSAttributeDescription()
                    wasDeleted.name = "wasDeleted"
                    wasDeleted.attributeType = .BooleanAttributeType
                    wasDeleted.optional = false
                    wasDeleted.defaultValue = NSNumber(bool: false)
                    currentProps.append(wasDeleted)
                    
                    let note = NSAttributeDescription()
                    note.name = "note"
                    note.attributeType = .StringAttributeType
                    note.optional = true
                    currentProps.append(note)
                    
                    let syncStatus = NSAttributeDescription()
                    syncStatus.name = "syncStatus"
                    syncStatus.attributeType = .Integer16AttributeType
                    syncStatus.optional = false
                    syncStatus.defaultValue = NSNumber(integer: 0)
                    currentProps.append(syncStatus)
                    
                    ent.properties = currentProps
                    entities.append(ent)
                }
                
                modifiableModel.entities = entities
                return modifiableModel
            }
        }
        
        return nil
    }
}

public class CGDataStore: NSObject {
    var _masterManagedObjectContext: NSManagedObjectContext?
    var masterManagedObjectContext: NSManagedObjectContext? {
        if let m = _masterManagedObjectContext { return m }
        _masterManagedObjectContext = self.setupManagedObjectContextWithConcurrencyType(.MainQueueConcurrencyType)
        return _masterManagedObjectContext
    }
    
    var _backgroundManagedObjectContext: NSManagedObjectContext?
    public var backgroundManagedObjectContext: NSManagedObjectContext? {
        if let b = _backgroundManagedObjectContext { return b }
        _backgroundManagedObjectContext = self.setupManagedObjectContextWithConcurrencyType(.PrivateQueueConcurrencyType)
        return _backgroundManagedObjectContext
    }
    
    var _managedObjectModel: NSManagedObjectModel?
    var managedObjectModel: NSManagedObjectModel? {
        if let m = _managedObjectModel { return m }
        _managedObjectModel = CGDataController.modifiedObjectModelWithStoreName(storeName)
        return _managedObjectModel
    }
    
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator?
    var persistentStoreCoordinator: NSPersistentStoreCoordinator? {
        if let p = _persistentStoreCoordinator { return p }
        if let model = managedObjectModel {
            let fileManager = NSFileManager.defaultManager()
            let docPath = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as! NSURL
            let storeURL = docPath.URLByAppendingPathComponent("\(storeName).sqlite")
            
            let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]
            
//            let options = NSDictionary(dictionary: [ NSMigratePersistentStoresAutomaticallyOption : NSNumber(bool: true), NSInferMappingModelAutomaticallyOption : NSNumber(bool: true) ])
            
            var error: NSError?
            _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            if let p = _persistentStoreCoordinator {
                let store = p.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options, error: &error)
                if let s = store {
                    return _persistentStoreCoordinator
                } else if let err = error {
                    println("Error: \(err.localizedDescription)")
                }
            }
        }
        return nil
    }
    
    public let storeName: String
    
    public init(sName: String) {
        storeName = sName
        super.init()
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: nil, usingBlock: { note in
            if let context = self.masterManagedObjectContext {
                let notifiedContext = note.object as! NSManagedObjectContext
                if notifiedContext != context {
                    context.performBlock({_ in context.mergeChangesFromContextDidSaveNotification(note) })
                }
            }
        })
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: nil)
    }
    
    public func save() {
        if let context = backgroundManagedObjectContext {
            context.performBlockAndWait({_ in
                var error: NSError?
                let saved = context.save(&error)
                if !saved { if let err = error { println("Error: \(err.localizedDescription)") } }
                NSNotificationCenter.defaultCenter().postNotificationName(kCGDataControllerFinishedSaveNotification, object: nil)
            })
        }
    }
    
    public func saveMasterContext() {
        if let context = masterManagedObjectContext {
            context.performBlockAndWait({_ in
                var error: NSError?
                let saved = context.save(&error)
                if !saved { if let err = error { println("Error: \(err.localizedDescription)") } }
                NSNotificationCenter.defaultCenter().postNotificationName(kCGDataControllerFinishedSaveNotification, object: nil)
            })
        }
    }
    
    public func resetStore() {
        self.save()
        self.saveMasterContext()
        _backgroundManagedObjectContext = nil
        _masterManagedObjectContext = nil
        _managedObjectModel = nil
        _persistentStoreCoordinator = nil
    }
    
    public func deleteStore() {
        let fileManager = NSFileManager.defaultManager()
        let docPath = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as! NSURL
        let storeURL = docPath.URLByAppendingPathComponent("\(storeName).sqlite")
        if let storePath = storeURL.path {
            let exists = fileManager.fileExistsAtPath(storePath)
            if exists {
                var error: NSError?
                fileManager.removeItemAtPath(storePath, error: &error)
                if let err = error { println("Error: \(err.localizedDescription)") } else {
                    if let context = self.masterManagedObjectContext {
                        for ct in context.registeredObjects {
                            context.deleteObject(ct as! NSManagedObject)
                        }
                    }
                }
            }
            _persistentStoreCoordinator = nil
            self.persistentStoreCoordinator
        }
    }
    
    /* Setup Contexts */
    
    private func setupManagedObjectContextWithConcurrencyType(concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext? {
        if let coord = self.persistentStoreCoordinator {
            let context = NSManagedObjectContext(concurrencyType: concurrencyType)
            context.performBlockAndWait({_ in context.persistentStoreCoordinator = coord })
            return context
        }
        return nil
    }
    
    /* Generate Status Dictionary */
    
    public func statusDictionaryForClass(className: String) -> NSDictionary? {
        if let context = backgroundManagedObjectContext {
            var error: NSError?
            let request = NSFetchRequest(entityName: className)
            let count = context.countForFetchRequest(request, error: &error)
            
            if let err = error {
                println("Error: \(err.localizedDescription)")
            } else {
                var ret = NSMutableDictionary()
                let dateObj = self.managedObjectsForClass(className, sortedByKey: "updatedAt", ascending: false, withFetchLimit: 1)
                if let d = dateObj {
                    if d.count > 1 {
                        println("Error: Fetch for 1 item returned multiple")
                    } else if d.count == 0 {
                        ret.setObject(NSNumber(integer: count), forKey: "count")
                        ret.setObject("", forKey: "lastUpdatedAt")
                    } else {
                        let obj = d[0] as! NSManagedObject
                        ret.setObject(NSNumber(integer: count), forKey: "count")
                        ret.setObject(obj.updatedAt, forKey: "lastUpdatedAt")
                    }
                }
                return ret
            }
        }
        return nil
    }
    
    /* Generate New Object With Class */
    
    public func newManagedObjectForClass(className: String) -> NSManagedObject? {
        if let context = backgroundManagedObjectContext {
            let objTemp = NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: context) as? NSManagedObject
            if let obj = objTemp {
                let date = NSDate()
                obj.createdAt = date
                obj.updatedAt = date
                return obj
            }
        }
        return nil
    }
    
    /* Single Object Existence */
    
    public func objectExistsOnDiskWithClass(className: String, andObjectId objId: String) -> Bool {
        let obj = self.managedObjectForClass(className, withId: objId)
        if let o = obj { return true } else { return false }
    }
    
    /* Single Managed Object Fetch */
    
    public func managedObjectWithManagedID(objID: NSManagedObjectID) -> NSManagedObject? {
        if let context = backgroundManagedObjectContext {
            return context.objectRegisteredForID(objID)
        }
        return nil
    }
    
    public func managedObjectForClass(className: String, withId objId: String) -> NSManagedObject? {
        let objArray = self.managedObjectsForClass(className, sortedByKey: "createdAt", ascending: false, withPredicate: NSPredicate(format: "objectId like %@", objId))
        if let a = objArray {
            if a.count == 0 { return nil } else if a.count > 1 {
                assert(false, "Error: More than one object has objectId <\(objId)>")
            }
            return a[0] as? NSManagedObject
        }
        return nil
    }
    
    public func nth(num: Int, managedObjectForClass className: String) -> NSManagedObject? {
        let objArray = self.managedObjectsForClass(className, sortedByKey: "updatedAt", ascending: false)
        if let a = objArray { if a.count >= num { return a[num - 1] as? NSManagedObject } }
        return nil
    }
    
    /* Single Dictionary Fetch */
    
    public func managedObjAsDictionaryWithManagedID(objID: NSManagedObjectID) -> NSDictionary? {
        if let context = backgroundManagedObjectContext {
            let manObjTemp = context.objectRegisteredForID(objID)
            if let manObj = manObjTemp {
                return self.managedObjAsDictionaryForClass(manObj.entity.managedObjectClassName, withId: manObj.objectId)
            }
        }
        return nil
    }
    
    public func managedObjAsDictionaryForClass(className: String, withId objId: String) -> NSDictionary? {
        let objArray = self.managedObjsAsDictionariesForClass(className, sortedByKey: "createdAt", ascending: false, withPredicate: NSPredicate(format: "objectId like %@", objId))
        if let a = objArray {
            if a.count == 0 || a.count > 1 { assert(false, "Error: More than one object has objectId <\(objId)>") }
            return a[0] as? NSDictionary
        }
        return nil
    }
    
    /* Fetch Objects */
    
    public func managedObjectsForClass(className: String, sortedByKey key: String? = nil, ascending ascend: Bool = true, withFetchLimit limit: Int = 0, withBatchSize num: Int = 0, withPredicate predicate: NSPredicate? = nil) -> [AnyObject]? {
        return self.objectsForClass(className, sortedByKey: key, ascending: ascend, withFetchLimit: limit, withBatchSize: num, withPredicate: predicate, asDictionaries: false)
    }
    
    /* Fetch Objects as Dictionaries for quick lookup */
    
    public func managedObjsAsDictionariesForClass(className: String, sortedByKey key: String? = nil, ascending ascend: Bool = true, withFetchLimit limit: Int = 0, withBatchSize num: Int = 0, withPredicate predicate: NSPredicate? = nil) -> [AnyObject]? {
        return self.objectsForClass(className, sortedByKey: key, ascending: ascend, withFetchLimit: limit, withBatchSize: num, withPredicate: predicate, asDictionaries: true)
    }
    
    private func objectsForClass(className: String, sortedByKey key: String? = nil, ascending ascend: Bool = true, withFetchLimit limit: Int = 0, withBatchSize num: Int = 0, withPredicate predicate: NSPredicate? = nil, asDictionaries dicts: Bool) -> [AnyObject]? {
        if let context = backgroundManagedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: className)
            fetchRequest.predicate = predicate
            fetchRequest.fetchBatchSize = num
            if limit > 0 { fetchRequest.fetchLimit = limit }
            if let k = key { fetchRequest.sortDescriptors = [ NSSortDescriptor(key: k, ascending: ascend) ] }
            if dicts { fetchRequest.resultType = .DictionaryResultType }
            
            var results: [AnyObject]?
            var error: NSError?
            context.performBlockAndWait({_ in
                results = context.executeFetchRequest(fetchRequest, error: &error)
                if let err = error { println("Error: \(err.localizedDescription)") }
            })
            return results;
        }
        return nil
    }
}