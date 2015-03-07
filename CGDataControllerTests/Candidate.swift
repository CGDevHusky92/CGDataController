//
//  Candidate.swift
//  CGDataController
//
//  Created by Chase Gorectke on 3/5/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import Foundation
import CoreData

import CGDataController

class Candidate: CGManagedObject {

    @NSManaged var encounter_date: NSDate
    @NSManaged var first_name: String
    @NSManaged var isGood: NSNumber
    @NSManaged var last_name: String
    @NSManaged var recruiterId: Recruiter

}
