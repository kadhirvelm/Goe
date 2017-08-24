//
//  ExploreInterestViewController.swift
//  Goe
//
//  Created by Kadhir M on 9/14/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class ExploreInterestViewController: UIViewController {

    let goeCoreData = GoeCoreData()
    let goeCloudData = GoeCloudKit()
    var loggedInUser: CKRecord?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tempLoggedInUser = goeCoreData.retrieveData("User")
        let loggedInUser = tempLoggedInUser![0] as? User
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "ID = '\((loggedInUser?.user_ID)!)' "))
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if records?.count > 0 {
                    self.loggedInUser = records![0]
                } else {
                    self.loggedInUser = nil
                }
            }
        }
    }

    @IBAction func yesPlease(sender: UIButton) {
        if loggedInUser != nil {
            let currStatus = loggedInUser?.valueForKey("Status") as? Int
            loggedInUser!["Status"] = currStatus! | 2
            goeCloudData.saveRecord(loggedInUser!)
            let confirmingRequest = UIAlertController(title: "", message: "Awesome, you'll be the first to know when this feature is complete.", preferredStyle: UIAlertControllerStyle.Alert)
            let action = UIAlertAction(title: "Sounds Good", style: UIAlertActionStyle.Default, handler: {action in self.navigationController?.popViewControllerAnimated(true)})
            confirmingRequest.addAction(action)
            self.presentViewController(confirmingRequest, animated: true, completion: nil)
        }
    }
}
