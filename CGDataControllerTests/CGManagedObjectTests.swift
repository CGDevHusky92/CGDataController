//
//  CGManagedObjectTests.swift
//  CGDataController
//
//  Created by Chase Gorectke on 3/5/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import UIKit
import XCTest

import CGDataController

class CGManagedObjectTests: XCTestCase {

    override func setUp() {
        super.setUp()
        CGDataController.testBundleClass = self.classForCoder
        CGDataController.initSharedDataWithStoreName("TestModel", makeDefault: true)
    }
    
    override func tearDown() {
        CGDataController.sharedData().deleteStore()
        super.tearDown()
    }
    
    func testUpdateFromJSONString() {
        
    }
    
    func testConvertToJSONString() {
        
    }
    
    func testSubclassProperties() {
        let newRecruiter = CGDataController.sharedData().newManagedObjectForClass("Recruiter") as! Recruiter
        
        let recId = newRecruiter.objectId
        let createdAt = newRecruiter.createdAt
        let updatedAt = newRecruiter.updatedAt
        let note = newRecruiter.note
        let wasDeleted = newRecruiter.wasDeleted
        let syncStatus = newRecruiter.syncStatus
        
        newRecruiter.username = "crgorect"
        
        CGDataController.sharedData().save()
        
        let rec = CGDataController.sharedData().managedObjectForClass("Recruiter", withId: recId) as! Recruiter
        
        rec.functionDoesStuff()
        
        XCTAssertEqual(recId, rec.objectId, "objectId exists and is persisting.")
        XCTAssertEqual(createdAt, rec.createdAt, "createdAt exists and is persisting.")
        XCTAssertEqual(updatedAt, rec.updatedAt, "updatedAt exists and is persisting.")
        if let testNote = rec.note {
            XCTAssertEqual(note!, testNote, "note exists and is persisting.")
        }
        XCTAssertEqual(wasDeleted, rec.wasDeleted, "wasDeleted exists and is persisting.")
        XCTAssertEqual(syncStatus, rec.syncStatus, "syncStatus exists and is persisting.")
    }
    
    func testSubclassDictionary() {
        let newRecruiter = CGDataController.sharedData().newManagedObjectForClass("Recruiter") as! Recruiter
        
        let recId = newRecruiter.objectId
        let createdAt = newRecruiter.createdAt
        let updatedAt = newRecruiter.updatedAt
        let note = newRecruiter.note
        let wasDeleted = newRecruiter.wasDeleted
        let syncStatus = newRecruiter.syncStatus
        
        newRecruiter.username = "crgorect"
        
        CGDataController.sharedData().save()
        
        let rec = CGDataController.sharedData().managedObjectForClass("Recruiter", withId: recId) as! Recruiter
        
        rec.dictionaryFromObject()
        
        XCTAssert(true, "Printing dictionary")
        
    }

}
