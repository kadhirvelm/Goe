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
    
    /** All returned record for use when saving. */
    var returnRecords: [CKRecord]?
    /** Goe core data helper. */
    let goeCoreData = GoeCoreData()
    /** Public database. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    //MARK: Utility Methods Begin
    
    /* Creates a new user + respective profile to be saved in CloudKit. */
    func createUser(userName: String, userID: String, profilePicture: UIImage?, emailAddress: String, facebookUser: Bool, completionHandler: (NSError?) -> Void) {
        let newUser = CKRecord(recordType: "User")
        let newUserProfile = CKRecord(recordType: "Profile")
        
        let userNameSplit = userName.componentsSeparatedByString(" ")
        let userName = userNameSplit[0] + "." + userNameSplit[1]
        newUser["Name"] = userName
        newUser["ID"] = "\(userName.hash)"
        createProfileSubscription(newUser["ID"] as! String)
        if facebookUser {
            newUser["Facebook_ID"] = userID
        } else {
            newUser["Facebook_ID"] = 0
        }
        newUser["Email"] = emailAddress
        newUser["Goe_Rating"] = 0
        newUser["Status"] = 1
        newUser["Details"] = ["Welcome to Goe. Edit your bio with the settings button in the top right."]
        var length = arc4random_uniform(20).hashValue
        if length < 4 {
            length += arc4random_uniform(20).hashValue
        }
        newUser["Password"] = randomStringWithLength(length) as String
        let imageAsset = changeImageToAsset(profilePicture!)
        newUser["Picture"] = imageAsset
        newUserProfile["User"] = CKReference(record: newUser, action: .DeleteSelf)
        newUserProfile["User_ID"] = "\(userName.hash)"
        newUserProfile["User_Name"] = userName
        let userReference = newUser.recordID.recordName
        saveMultipleRecords([newUser, newUserProfile], counter: 0, completionHandler: completionHandler)
        goeCoreData.deleteAllData("User")
        goeCoreData.createUser(userName, userID: "\(userName.hash)", profilePicture: UIImageJPEGRepresentation(profilePicture!,1.0), userReference: userReference)
    }
    
    /** Creates a profile subscription. */
    private func createProfileSubscription(User_ID: String) {
        let predicate = NSPredicate(format: "User_ID = '\(User_ID)'")
        let subscription = CKSubscription(recordType: "Profile", predicate: predicate, options: .FiresOnRecordUpdate)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = "Profile Has Changed"
        notificationInfo.soundName = UILocalNotificationDefaultSoundName
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
    
    /** Generates a random string given length len. */
    private func randomStringWithLength (len : Int) -> NSString {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()<>?:/*-+"
        let randomString : NSMutableString = NSMutableString(capacity: len)
        for _ in 0 ..< len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.characterAtIndex(Int(rand)))
        }
        return randomString
    }
    
    /** Changes a UIImage into a CKAsset, so it can be saved on the cloud. */
    func changeImageToAsset(imageToBeSaved: UIImage) -> CKAsset{
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent("lastimage")
        let path = fileURL!.path!
        UIImagePNGRepresentation(imageToBeSaved)!.writeToFile(path, atomically: true)
        return CKAsset(fileURL: NSURL(fileURLWithPath: path))
    }
    
    /** Given an asset, converts it to an uiimage. */
    func changeAssetToImage(asset: CKAsset) -> UIImage? {
        let url = asset.fileURL
        if let imagedata = NSData(contentsOfFile: url.path!) {
            return UIImage(data: imagedata)
        }
        return nil
    }
    
    /** Given a userID, goes and fetches the associated user's Profile. */
    func fetchProfile(userID: String, completionHandler: (CKRecord?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let query = CKQuery(recordType: "Profile", predicate: NSPredicate(format: "User_ID = '\(userID)' "))
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if error == nil {
                    if records?.count > 0 {
                        completionHandler(records![0])
                    } else {
                        completionHandler(nil)
                    }
                } else {
                    print(error)
                }
            }
        }
    }
    
    /** Given a particular userID, fetches the associated User. */
    func fetchUser(userID: String, completionHandler: (CKRecord?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "Facebook_ID = '\(userID)' "))
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if records?.count > 0 {
                    completionHandler(records![0])
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
    /** Converts the CKAsset into NSData of the user's profilePicture. */
    func getProfilePhoto(records: CKRecord) -> NSData? {
        if let photo = records.valueForKey("Picture") as? CKAsset {
            let url = photo.fileURL
            if let imagedata = NSData(contentsOfFile: url.path!) {
                return imagedata
            }
        }
        return nil
    }
    
    /** Converts the CKAsset into NSData of the user's profilePicture. */
    func getAdventurePhoto(records: CKRecord) -> NSData? {
        if let photo = records.valueForKey("Photo") as? CKAsset {
            let url = photo.fileURL
            let imagedata = NSData(contentsOfFile: url.path!)
            return imagedata
        }
        return nil
    }
    
    /** Class that saves multiple CKRecords. */
    func saveMultipleRecords(saveTheseRecords: [CKRecord], counter: Int, completionHandler: (NSError?) -> Void) {
        saveRecord(saveTheseRecords, counter: counter, completionHandler: completionHandler)
    }
    
    /** Given a certain CKRecord, it will save it to CloudKit, but it also needs a counter which tells it which record in the CKRecord array it will save. */
    private func saveRecord(saveThisRecord: [CKRecord], counter: Int, completionHandler: (NSError?) -> Void) {
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        
        publicDatabase.saveRecord(saveThisRecord[counter]) { (record, error) -> Void in
            completionHandler(error)
            if saveThisRecord.count > (counter + 1) {
                self.saveMultipleRecords(saveThisRecord, counter: counter+1, completionHandler: completionHandler)
            }
        }
    }
    
    /** Given a particular userID, fetches the associated User. */
    func fetchProfileWithReference(recordID: CKRecordID, completionHandler: (CKRecord?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.publicDatabase.fetchRecordWithID(recordID, completionHandler: { (record: CKRecord?, error: NSError?) in
                if error == nil {
                    let userID = record?.valueForKey("ID") as? String
                    self.fetchProfile(userID!, completionHandler: completionHandler)
                } else {
                    print(error)
                }
            })
        }
    }
    
    /** Given a certain CKRecord, it will save it to CloudKit. */
    func saveRecord(saveThisRecord: CKRecord) {
        publicDatabase.saveRecord(saveThisRecord) { (record, error) -> Void in
            if error != nil {
                print(error)
            }
        }
    }
    
    /** Given a multiple CKRecords, it will save them to CloudKit. */
    @nonobjc func saveRecord(saveThisRecord: CKRecord, completionHandler: (CKRecord?)->Void) {
        publicDatabase.saveRecord(saveThisRecord) { (record, error) in
            if error == nil {
                completionHandler(record)
            } else {
                print("Saving record error: \(error)")
                completionHandler(nil)
            }
        }
    }
    
    /** Given a certain CKRecord, it will delete it from CloudKit. DANGEROUS. */
    func deleteRecord(deleteThisRecord: CKRecord) {
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        publicDatabase.deleteRecordWithID(deleteThisRecord.recordID) { (record, error) -> Void in
            if error != nil {
                print("Deleting record error: \(error)")
            }
        }
    }
    
    /** Fetches a CKRecord given a reference.*/
    func fetchReference(reference: CKReference, completionHandler: (CKRecord?) -> Void) {
        publicDatabase.fetchRecordWithID(reference.recordID) { (record, error) in
            if error == nil {
                completionHandler(record)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    /** Given a CKRecord, will refresh it with the latest version. */
    func refreshCKRecord(recordToUpdate: CKRecord, completionHandler: (CKRecord?)-> ()) {
        publicDatabase.fetchRecordWithID(recordToUpdate.recordID) { (fetchedRecord, error) in
            if error == nil {
                completionHandler(fetchedRecord)
            } else {
                completionHandler(nil)
            }
        }
    }

}
