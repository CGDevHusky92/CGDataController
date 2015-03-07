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
    var dataStores = [ String : CGDataStore ]()
    
    public static var testBundleClass: AnyClass?
    
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
        let d = CGDataController.sharedDataController
        if let s = d.defaultStoreName { return self.sharedDataWithName(s) }
        assert(false, "You must set a store name by calling +(id)initSharedDataWithStoreName: before making calls to +(id)sharedData")
    }
    
    public class func sharedDataWithName(sName: String) -> CGDataStore {
        let d = CGDataController.sharedDataController
        if let s = d.dataStores[sName] { return s }
        assert(false, "You must set a store name by calling +(id)initSharedDataWithStoreName: before making calls to +(id)sharedDataWithName:")
    }
    
    private class func getModelStoreURL(storeName: String, withBundle bundle: NSBundle) -> NSURL? {
        var modelURL = bundle.URLForResource(storeName, withExtension: "mom")
        if let mURL = modelURL {} else {
            modelURL = bundle.URLForResource(storeName, withExtension: "momd")
            if let mURL = modelURL {
                modelURL = mURL.URLByAppendingPathComponent("\(storeName).mom")
            }
        }
        return modelURL
    }
    
    public class func modifiedObjectModelWithStoreName(storeName: String) -> NSManagedObjectModel? {
        let bundle: NSBundle
        if let tBundle: AnyClass = testBundleClass {
            bundle = NSBundle(forClass: tBundle)
        } else {
            bundle = NSBundle.mainBundle()
        }
        
        let urlTemp = self.getModelStoreURL(storeName, withBundle: bundle)
        if let modelURL = urlTemp {
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
        } else {
            assert(false, "The model could not be found. Check to make sure you have the correct model name and extension.")
        }
        return nil
    }
}

//// MARK: - Core Data stack
//
//lazy var applicationDocumentsDirectory: NSURL = {
//    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.revisionworks.TestData" in the application's documents Application Support directory.
//    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
//    return urls[urls.count-1] as! NSURL
//    }()
//
//lazy var managedObjectModel: NSManagedObjectModel = {
//    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
//    let modelURL = NSBundle.mainBundle().URLForResource("TestData", withExtension: "momd")!
//    return NSManagedObjectModel(contentsOfURL: modelURL)!
//    }()
//
//lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
//    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
//    // Create the coordinator and store
//    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
//    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("TestData.sqlite")
//    var error: NSError? = nil
//    var failureReason = "There was an error creating or loading the application's saved data."
//    if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
//        coordinator = nil
//        // Report any error we got.
//        var dict = [String: AnyObject]()
//        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
//        dict[NSLocalizedFailureReasonErrorKey] = failureReason
//        dict[NSUnderlyingErrorKey] = error
//        error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
//        // Replace this with code to handle the error appropriately.
//        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//        NSLog("Unresolved error \(error), \(error!.userInfo)")
//        abort()
//    }
//    
//    return coordinator
//    }()
//
//lazy var managedObjectContext: NSManagedObjectContext? = {
//    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
//    let coordinator = self.persistentStoreCoordinator
//    if coordinator == nil {
//        return nil
//    }
//    var managedObjectContext = NSManagedObjectContext()
//    managedObjectContext.persistentStoreCoordinator = coordinator
//    return managedObjectContext
//    }()
//
//// MARK: - Core Data Saving support
//
//func saveContext () {
//    if let moc = self.managedObjectContext {
//        var error: NSError? = nil
//        if moc.hasChanges && !moc.save(&error) {
//            // Replace this implementation with code to handle the error appropriately.
//            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            NSLog("Unresolved error \(error), \(error!.userInfo)")
//            abort()
//        }
//    }
//}

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
                        let obj = d[0] as! CGManagedObject
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
    
    public func newManagedObjectForClass(className: String) -> CGManagedObject? {
        if let context = backgroundManagedObjectContext {
            let objTemp = NSEntityDescription.insertNewObjectForEntityForName(className, inManagedObjectContext: context) as? CGManagedObject
            if let obj = objTemp {
                let date = NSDate()
                obj.createdAt = date
                obj.updatedAt = date
                return obj
            } else {
                println("Error")
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
    
    public func managedObjectWithManagedID(objID: NSManagedObjectID) -> CGManagedObject? {
        if let context = backgroundManagedObjectContext {
            return context.objectRegisteredForID(objID) as? CGManagedObject
        }
        return nil
    }
    
    public func managedObjectForClass(className: String, withId objId: String) -> CGManagedObject? {
        let objArray = self.managedObjectsForClass(className, sortedByKey: "createdAt", ascending: false, withPredicate: NSPredicate(format: "objectId like %@", objId))
        if let a = objArray {
            if a.count == 0 { return nil } else if a.count > 1 {
                assert(false, "Error: More than one object has objectId <\(objId)>")
            }
            return a[0] as? CGManagedObject
        }
        return nil
    }
    
    public func nth(num: Int, managedObjectForClass className: String) -> CGManagedObject? {
        let objArray = self.managedObjectsForClass(className, sortedByKey: "updatedAt", ascending: false)
        if let a = objArray { if a.count >= num { return a[num - 1] as? CGManagedObject } }
        return nil
    }
    
    /* Single Dictionary Fetch */
    
    public func managedObjAsDictionaryWithManagedID(objID: NSManagedObjectID) -> NSDictionary? {
        if let context = backgroundManagedObjectContext {
            let manObjTemp = context.objectRegisteredForID(objID) as? CGManagedObject
            if let manObj = manObjTemp {
                return self.managedObjAsDictionaryForClass(manObj.entity.managedObjectClassName, withId: manObj.objectId as String)
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