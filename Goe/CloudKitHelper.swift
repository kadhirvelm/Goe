//
//  CloudKitHelper.swift
//  Goe
//
//  Created by Kadhir M on 1/14/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitHelper {
    var container : CKContainer
    var publicDB : CKDatabase
    let privateDB : CKDatabase
    
    init() {
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    func saveRecord(todo : NSString) {
        let test = CKRecord(recordType: "Test")
        test.setValue(test, forKey: "todotext")
        publicDB.saveRecord(test, completionHandler: { (record, error) -> Void in
            NSLog("Saved to cloud kit")
        })
    }
    
}
