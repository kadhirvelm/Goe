//
//  User+CoreDataProperties.swift
//  Goe
//
//  Created by Kadhir M on 5/16/16.
//  Copyright © 2016 Expavar. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var user_ID: String?
    @NSManaged var user_Name: String?
    @NSManaged var picture: NSData?
    @NSManaged var user_reference: String?

}
