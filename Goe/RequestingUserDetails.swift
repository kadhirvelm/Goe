//
//  requestinUserDetails.swift
//  Goe
//
//  Created by Kadhir M on 1/30/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class requestingUserDetails: UIViewController {

    //MARK: User outlets
    
    /** Next time background. */
    @IBOutlet weak var no_background: UIView!
    /** Join me background. */
    @IBOutlet weak var yes_background: UIView!
    /** The no button.*/
    @IBOutlet weak var noButton: UIButton!
    /** The yes button.*/
    @IBOutlet weak var yesButton: UIButton!

    //MARK: Helper functions
    
    /** Public database.*/
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    /** Goe cloud data utility helper.*/
    let goeCloudData = GoeCloudKit()
    /** Utilties helper function. */
    var goeUtilities = GoeUtilities()
    
    //MARK: UI Variables
    
    /** The particular adventure user is trying to join.*/
    var Adventure: CKRecord?
    /** The requesting user.*/
    var requestingUser: CKRecord?
    /** Total server responses. */
    var totalServerResponses = 2
    /** Intermediary adventure saver responses. */
    var adventureChanges = 0
    /** Holds the constants for this adventure. */
    enum ADVENTURE_CONSTANTS {
        static let SERVER_RESPONSES = 2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustYesAndNo()
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: nil)
    }
    
    /** Adjusts the yes and no buttons to be circular.*/
    func adjustYesAndNo() {
        no_background.layer.cornerRadius = 15
        no_background.layer.borderColor = UIColor.blackColor().CGColor
        noButton.layer.cornerRadius = 15
        no_background.layer.borderWidth = 1.5
        yes_background.layer.cornerRadius = 15
        yes_background.layer.borderColor = UIColor.blackColor().CGColor
        yesButton.layer.cornerRadius = 15
        yes_background.layer.borderWidth = 1.5
        self.view.bringSubviewToFront(no_background)
        self.view.bringSubviewToFront(noButton)
        self.view.bringSubviewToFront(yes_background)
        self.view.bringSubviewToFront(yesButton)
    }
    
    //MARK: Profile adjusting functions
    
    /** Handler for when the host presses the Yes button.*/
    @IBAction func AcceptUser(sender: UIButton) {
        sender.enabled = false
        noButton.enabled = false
        if (Adventure!["Spots"] as? Int) >= 1 {
            adventureChanges = ADVENTURE_CONSTANTS.SERVER_RESPONSES
            startMovingRequestingUser(true)
        } else {
            handleNotEnoughSpots()
        }
    }
    
    /** Presents a view controller that indicates there aren't enough spots. */
    func handleNotEnoughSpots() {
        let username = requestingUser?.valueForKey("Name") as? String
        let confirmingRequest = UIAlertController(title: "Accepting Error", message: "Looks like your adventure doesn't have enough spots in it to accept \(goeUtilities.splitUserName(username!))", preferredStyle: UIAlertControllerStyle.Alert)
        confirmingRequest.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Destructive, handler: { action in self.navigationController?.popViewControllerAnimated(true)}))
        self.presentViewController(confirmingRequest, animated: true, completion: nil)
    }
    
    /** Handler for when the host presses the No button.*/
    @IBAction func rejectUser(sender: UIButton) {
        sender.enabled = false
        yesButton.enabled = false
        adventureChanges = 1
        startMovingRequestingUser(false)
    }
    
    /** Starts the movement and processing of users.*/
    func startMovingRequestingUser(accept: Bool) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), {
            if accept {
                self.checkForAdventureHistory()
                self.moveUserIntoAttendingList()
            }
            self.moveUserOutOfRequestingList()
            self.fetchProfile((self.requestingUser!.valueForKey("ID") as? String)!, accepted: accept)
        })
    }
    
    /** Checks if this adventure has an adventure history, and appends this user to the attending users list. */
    func checkForAdventureHistory() {
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let id = (Adventure!["ID"] as? Int)!
        let predicate = NSPredicate(format: "ID = \(id)")
        let query = CKQuery(recordType: "Adventure_History", predicate: predicate)
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            if error == nil {
                if records?.count > 0{
                    self.appendCurrentUserToAttendingList(records![0])
                } else {
                    self.createAdventureHistoryCKRecord()
                }
            } else {
                print("Adventure history error: \(error)")
            }
        }
    }
    
    /** Appends the current user to the attending adventure history list. */
    func appendCurrentUserToAttendingList(adventure_history: CKRecord) {
        var currentAttendingUsers = adventure_history["User_Attended"] as? [CKReference]
        currentAttendingUsers?.append(CKReference(record: requestingUser!, action: CKReferenceAction.None))
        adventure_history["User_Attended"] = currentAttendingUsers
        var currentRatings = adventure_history["Ratings"] as? [Double]
        currentRatings![2] += 1
        adventure_history["Ratings"] = currentRatings
        goeCloudData.saveRecord(adventure_history)
    }
    
    /** Creates the adventure history based on the adventure details. */
    func createAdventureHistoryCKRecord(){
        let newAdventureHistory = CKRecord(recordType: "Adventure_History")
        newAdventureHistory["Description"] = Adventure!["Description"] as? String
        newAdventureHistory["ID"] = Adventure!["ID"] as? Int
        newAdventureHistory["Name"] = Adventure!["Name"] as? String
        let image = (Adventure!["Photo"] as? CKAsset)?.fileURL
        newAdventureHistory["Photo"] = CKAsset.init(fileURL: image!)
        newAdventureHistory["Start_Date"] = Adventure!["Start_Date"] as? NSDate
        newAdventureHistory["End_Date"] = Adventure!["End_Date"] as? NSDate
        newAdventureHistory["User_Host"] = Adventure!["User_Host"] as? CKReference
        newAdventureHistory["Ratings"] = [0.0,0.0,2.0]
        newAdventureHistory["User_Attended"] = [CKReference(record: requestingUser!, action: .None)]
        newAdventureHistory["User_Host"] = Adventure!["User_Host"] as? CKReference
        newAdventureHistory["Equipment"] = Adventure!["Equipment"] as? String
        newAdventureHistory["Estimated_Cost"] = Adventure!["Estimated_Cost"] as? String
        newAdventureHistory["Origin"] = Adventure!["Origin"] as? CLLocation
        newAdventureHistory["Destination"] = Adventure!["Destination"] as? CLLocation
        newAdventureHistory["Tags"] = [Adventure!["Category"] as! String]
        goeCloudData.saveRecord(newAdventureHistory)
    }
    
    /** Moves user into the attending list for the adventure. */
    func moveUserIntoAttendingList() {
        var new_usersattending_list = Adventure!["User_Attending"] as? [CKReference] ?? [] as [CKReference]
        let tempUser = CKReference(record: requestingUser!, action: CKReferenceAction.None)
        new_usersattending_list.append(tempUser)
        Adventure!["User_Attending"] = new_usersattending_list
        Adventure!["Spots"] = (Adventure!["Spots"] as? Int)! - 1
        intermediaryAdventureSaver()
    }
    
    /** Moves user out of requesting list. */
    func moveUserOutOfRequestingList() {
        var new_usersrequesting_list = Adventure!["User_Requesting"] as! [CKReference]
        let tempUser = CKReference(record: requestingUser!, action: CKReferenceAction.None)
        new_usersrequesting_list.removeAtIndex((new_usersrequesting_list.indexOf(tempUser))!)
        Adventure!["User_Requesting"] = new_usersrequesting_list
        intermediaryAdventureSaver()
    }
    
    /** Handles the saving responses. */
    func intermediaryAdventureSaver() {
        dispatch_async(dispatch_get_main_queue()) {
            self.adventureChanges -= 1
            if self.adventureChanges == 0 {
                self.goeCloudData.saveRecord(self.Adventure!, completionHandler: self.handleServerResponse)
            }
        }
    }
    
    /** Goes and fetches the profile of the requesting user and then decides which subsequent method to go to based on acceptance.*/
    func fetchProfile(userID: String, accepted: Bool) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            let query = CKQuery(recordType: "Profile", predicate: NSPredicate(format: "User_ID = '\(userID)' "))
            self.publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if error == nil {
                    if accepted {
                        self.addAdventureToProfile(records![0])
                    } else {
                        self.addAdventureToRecentlyRejectedFrom(records![0])
                    }
                } else {
                    print(error)
                    //Handle error case
                }
            }
        }
    }
    
    /** Adds the current adventure to the reqeuesting user's profile.*/
    func addAdventureToProfile(records: CKRecord) {
        var currentAdventuresAttending = records["Adventure_Attending"] as? [CKReference] ?? [] as [CKReference]
        let newAdventure = CKReference(record: Adventure!, action: CKReferenceAction.None)
        currentAdventuresAttending.append(newAdventure)
        records["Adventure_Attending"] = currentAdventuresAttending
        goeCloudData.saveRecord(records, completionHandler: handleServerResponse)
    }
    
    /** Adds the current adventure to the requesting user's rejected list.*/
    func addAdventureToRecentlyRejectedFrom(records: CKRecord) {
        var currentRejectedAdventure = records["Adventure_Rejected"] as? [CKReference] ?? []
        let newRejectedAdventure = CKReference(record: Adventure!, action: CKReferenceAction.None)
        currentRejectedAdventure.append(newRejectedAdventure)
        records["Adventure_Rejected"] = currentRejectedAdventure
        goeCloudData.saveRecord(records, completionHandler: handleServerResponse)
    }
    
    /** After receiving all inputs from the server, handles the segue.*/
    func handleServerResponse(saveRecord: CKRecord?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.totalServerResponses -= 1
            if self.totalServerResponses == 0 {
                self.goeUtilities.segueAndForceReloadProfileViewController()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? AdventureUserDetailViewController {
            destination.viewingUserDetail = requestingUser
        }
    }
}
