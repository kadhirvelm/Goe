//
//  GoeCoreData.swift
//  Goe
//
//  Created by Kadhir M on 1/15/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import CoreData
import UIKit

class GoeCoreData {
    
    let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    /** Given a username, userID, and NSData profile picture, this method will create a new user and save it to Core Data. */
    func createUser(userName: String, userID: String, profilePicture: NSData?, userReference: String){
        let newUser = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
        newUser.setValue(userName, forKey: "user_Name")
        newUser.setValue(userID, forKey: "user_ID")
        newUser.setValue(profilePicture ?? UIImageJPEGRepresentation(UIImage(named: "XMark")!,1.0), forKey: "picture")
        newUser.setValue(userReference, forKey: "user_reference")
        do {
            try context.save()
        } catch {
            print("Errors")
        }
    }
    
    func saveUser(user: User) {
        do {
            try context.save()
        } catch let error as NSError{
            print(error.userInfo)
        }
    }
    
    /** Given an entity title, it will delete everything in core data associated with it. */
    func deleteAllData(entity: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            for managedObject in results {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedContext.deleteObject(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
    
    /* Given some entity string, it will return all the data associated with it in Core Data. */
    func retrieveData(entity: String) -> [AnyObject]? {
        do {
            let request = NSFetchRequest(entityName: entity)
            let results = try context.executeFetchRequest(request)
            return results
        } catch {
            print("Errors")
        }
        return nil
    }
    
    func clearCaches() {
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        let cache = NSFileManager.defaultManager()
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true) as [String]
        let filePath = "\(paths[0])/CloudKit/Assets"
        do {
            let contents = try cache.contentsOfDirectoryAtPath(filePath)
            for file in contents {
                try cache.removeItemAtPath("\(filePath)/\(file)")
            }
        } catch {
            print("Errors!")
        }
    }
    
}
