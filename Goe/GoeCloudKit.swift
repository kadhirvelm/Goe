//
//  GoeCloudKitHelper.swift
//  Goe
//
//  Created by Kadhir M on 1/15/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import CloudKit
import CoreData
import UIKit

class GoeCloudKit {
    
    var globaluserID = 0
    var returnRecords: [CKRecord]?
    let goeCoreData = GoeCoreData()
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    /* Creates a new user + respective profile to be saved in CloudKit. */
    func createUser(userName: String, userID: String, profilePicture: UIImage?, emailAddress: String, facebookUser: Bool) {
        let newUser = CKRecord(recordType: "User")
        let newUserProfile = CKRecord(recordType: "Profile")
        
        let userNameSplit = userName.componentsSeparatedByString(" ")
        let userName = userNameSplit[0] + "." + userNameSplit[1]
        newUser["userName"] = userName
        newUser["userID"] = "\(userName.hash)"
        globaluserID = userName.hash
        if facebookUser {
            newUser["facebookID"] = userID
        } else {
            newUser["facebookID"] = 0
        }
        createProfileSubscription()
        newUser["emailAddress"] = emailAddress
        newUser["GoeRating"] = 0
        newUser["userStatus"] = 1
        newUser["userDetails"] = ["Welcome to Goe! Adjust me with the edit button in the upper right corner."]
        var length = arc4random_uniform(20).hashValue
        if length < 4 {
            length += arc4random_uniform(20).hashValue
        }
        newUser["password"] = randomStringWithLength(length) as String
        let imageAsset = changeImageToAsset(profilePicture!)
        newUser["profilePicture"] = imageAsset
        newUserProfile["associatedUser"] = "\(userName.hash)"
        newUserProfile["associatedUserName"] = userName
        saveMultipleRecords([newUser, newUserProfile], counter: 0)
        goeCoreData.deleteAllData("User")
        goeCoreData.createUser(userName, userID: "\(userName.hash)", profilePicture: UIImageJPEGRepresentation(profilePicture!,1.0) ?? UIImageJPEGRepresentation(UIImage(named: "lightbulb-1")!,1.0))
    }
    
    func createProfileSubscription() {
        let predicate = NSPredicate(format: "associatedUser = '\(globaluserID)'")
        let subscription = CKSubscription(recordType: "Profile", predicate: predicate, options: .FiresOnRecordUpdate)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = "Profile Has Changed"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        publicDatabase.saveSubscription(subscription) { (subscription, error) -> Void in
            if error != nil {
                print(error)
            }
        }
    }
    
    /* Generates a random string given length len. */
    func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>?:/*-+"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        for _ in 0 ..< len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString
    }
    
    /* Changes a UIImage into a CKAsset, so it can be saved on the cloud. */
    func changeImageToAsset(imageToBeSaved: UIImage) -> CKAsset{
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent("lastimage")
        let path = fileURL.path!
        UIImagePNGRepresentation(imageToBeSaved)!.writeToFile(path, atomically: true)
        return CKAsset(fileURL: NSURL(fileURLWithPath: path))
    }
    
    /* Given a userID, goes and fetches the associated user's Profile. */
    func fetchProfile(userID: String, completionHandler: (CKRecord?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let query = CKQuery(recordType: "Profile", predicate: NSPredicate(format: "associatedUser = '\(userID)' "))
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if records?.count > 0 {
                    completionHandler(records![0])
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    /* Given a particular userID, fetches the associated User. */
    func fetchUser(userID: String, completionHandler: (CKRecord?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "facebookID = '\(userID)' "))
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if records?.count > 0 {
                    completionHandler(records![0])
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    /* Given a particular userID, fetches the associated User. */
    func fetchProfileWithReference(recordID: CKRecordID, completionHandler: (CKRecord?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.publicDatabase.fetchRecordWithID(recordID, completionHandler: { (record: CKRecord?, error: NSError?) in
                if error == nil {
                    let userID = record?.valueForKey("userID") as? String
                    self.fetchProfile(userID!, completionHandler: completionHandler)
                } else {
                    print(error)
                }
            })
        }
    }
    
    /* Converts the CKAsset into NSData of the user's profilePicture. */
    func getProfilePhoto(records: CKRecord) -> NSData? {
        if let photo = records.valueForKey("profilePicture") as? CKAsset {
            let url = photo.fileURL
            let imagedata = NSData(contentsOfFile: url.path!)!
            return imagedata
        }
        return nil
    }
    
    /* Converts the CKAsset into NSData of the user's profilePicture. */
    func getAdventurePhoto(records: CKRecord) -> NSData? {
        if let photo = records.valueForKey("AdventurePhoto") as? CKAsset {
            let url = photo.fileURL
            let imagedata = NSData(contentsOfFile: url.path!)!
            return imagedata
        }
        return nil
    }
    
    /* Class that saves multiple CKRecords. */
    func saveMultipleRecords(saveTheseRecords: [CKRecord], counter: Int) {
        saveRecord(saveTheseRecords, counter: counter)
    }
    
    /* Given a certain CKRecord, it will save it to CloudKit, but it also needs a counter which tells it which record in the CKRecord array it will save. */
    private func saveRecord(saveThisRecord: [CKRecord], counter: Int) {
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        
        publicDatabase.saveRecord(saveThisRecord[counter]) { (record, error) -> Void in
            if error != nil {
                print(error)
            }
            if saveThisRecord.count > (counter + 1) {
                self.saveMultipleRecords(saveThisRecord, counter: counter+1)
            }
        }
    }
    
    /* Given a certain CKRecord, it will save it to CloudKit. */
    func saveRecord(saveThisRecord: CKRecord) {
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        
        publicDatabase.saveRecord(saveThisRecord) { (record, error) -> Void in
            if error != nil {
                print(error)
            }
        }
    }
    
    /* Given a certain CKRecord, it will delete it from CloudKit. DANGEROUS. */
    func deleteRecord(deleteThisRecord: CKRecord) {
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        publicDatabase.deleteRecordWithID(deleteThisRecord.recordID) { (record, error) -> Void in
            print(error)
        }
    }

}
