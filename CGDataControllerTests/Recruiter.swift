//
//  Recruiter.swift
//  CGDataController
//
//  Created by Chase Gorectke on 3/5/15.
//  Copyright (c) 2015 Revision Works, LLC. All rights reserved.
//

import Foundation
import CoreData

import CGDataController

class Recruiter: CGManagedObject {

    @NSManaged var cand_count: NSNumber
    @NSManaged var username: String
    @NSManaged var candidateIds: NSSet

}
