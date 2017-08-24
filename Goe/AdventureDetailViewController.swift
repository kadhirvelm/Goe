//
//  AdventureDetailViewController.swift
//  Goe
//
//  Created by Kadhir M on 1/17/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import EventKit

class AdventureDetailViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    /* REQUIRED VARIABLE. The adventure to display. */
    var Adventure: CKRecord?
    
    //MARK: Adventure Outlets
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var spotsLeft: UILabel!
    @IBOutlet weak var adventureTitle: UILabel!
    @IBOutlet var background: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var requestToAttendButton: UIButton!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var AdventuringUsersCollectionView: UICollectionView!
    @IBOutlet weak var destination: UILabel!
    @IBOutlet weak var estimatedCost: UILabel!
    @IBOutlet weak var equipment: UILabel!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var usersLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyLogo: UIImageView!
    
    //MARK: Utility Helpers
    
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    let goeCoreData = GoeCoreData()
    let goeCloudData = GoeCloudKit()
    let goeLocation = GoeCoreLocationHelper()
    var goeUtilities = GoeUtilities()
    
    //MARK: Adventure UI Items
    /** Waiting for result alert controller.*/
    var waitingForResult = UIAlertController()
    /** Global waiting indicator for server activity.*/
    var globalIndicator = UIActivityIndicatorView()
    /** The logged in user's cloud data.*/
    var loggedInUser: CKRecord?
    /** The selected user when clicking on an attendee.*/
    var selectedUser: CKRecord?
    
    //MARK: Adventure Backend Items
    
    /** This adventure's ID.*/
    var AdventureID: String?
    /** All adventuring users.*/
    var AdventuringUsers = [[CKRecord?]]()
    /** Hosting goer.*/
    var hostingUser = [CKRecord?]()
    /** All attending goers.*/
    var attendingUsers = [CKRecord?]()
    /** Total server responses needed. */
    var totalServerResponses = 2
    
    
    //MARK: Methods Begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setParameters()
        if let destination = self.Adventure?.valueForKey("Destination") as? CLLocation {
            self.goeLocation.returnClosestCity(destination, completionHandler: self.setDestinationCity)
        }
        self.gatherAllAdventuringUsers()
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: self.scrollView!)
        self.performQueryToGetUser(self.setRequestButton)
    }
    
    /** Loads the adventure parameters onto the UI. */
    func setParameters() {
        if let adventurePhoto = Adventure?.valueForKey("Photo") as? CKAsset {
            let url = adventurePhoto.fileURL
            if NSData(contentsOfFile: url.path!) != nil {
                let imagedata = NSData(contentsOfFile: url.path!)
                if imagedata != nil {
                    photo.image = UIImage(data: imagedata!)
                }
            }
        }
        spotsLeft.text = "Spots: \((Adventure?.valueForKey("Spots") as? Int)!)"
        adventureTitle.text = Adventure?.valueForKey("Name") as? String
        UIView.transitionWithView(descriptionText, duration: 0.35, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.descriptionText.text = self.Adventure?.valueForKey("Description") as? String ?? "None"
            }, completion: nil)
        let startDate = NSDateFormatter.localizedStringFromDate((Adventure?.valueForKey("Start_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        let endDate = NSDateFormatter.localizedStringFromDate((Adventure?.valueForKey("End_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        Date.text = "\(startDate) - \(endDate)"
        category.text = Adventure?.valueForKey("Category") as? String ?? ""
        if let estimatedCostText = Adventure?.valueForKey("Estimated_Cost") as? String {
            estimatedCost.text = estimatedCostText
        }
        if let equipmentText = Adventure?.valueForKey("Equipment") as? String {
            equipment.text = equipmentText
        }
        let logo = Adventure?.valueForKey("Logo") as? CKAsset
        if logo != nil {
            let logo = goeCloudData.changeAssetToImage(logo!)
            if logo != nil {
                companyLogo?.image = logo!
            }
        }
    }
    
    /** Sets the destination city. */
    func setDestinationCity(city: String?, zipcode: String?) {
        if (city != nil && zipcode != nil) {
            destination.text = "\(city!), \(zipcode!)"
        }
    }
    
    /** Gathers all currently attending users specific to this adventure. */
    func gatherAllAdventuringUsers() {
        AdventuringUsers.removeAll()
        hostingUser.removeAll()
        attendingUsers.removeAll()
        AdventuringUsers.append(hostingUser)
        AdventuringUsers.append(attendingUsers)
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            self.getSingleAdventure("User_Host", index: 0)
            self.getAdventuringUsers("User_Attending", index: 1)
        }
    }
    
    /** Retrieves a single user. */
    func getSingleAdventure(keyword: String, index: Int) {
        let userReference = Adventure?.valueForKey(keyword) as! CKReference
        self.publicDatabase.fetchRecordWithID(userReference.recordID) { (fetchedUser, error) in
            self.AdventuringUsers[index].append(fetchedUser)
            self.reloadCollectionView()
        }
    }
    
    /** Retrieves multiple users. */
    func getAdventuringUsers(keyword: String, index: Int) {
        let usersAttending = Adventure?.valueForKey(keyword) as? [CKReference]
        if usersAttending?.count > 0 {
            let operationQueue = NSOperationQueue()
            for user in usersAttending! {
                operationQueue.addOperationWithBlock({
                    self.publicDatabase.fetchRecordWithID(user.recordID, completionHandler: { (fetchedUser, error) in
                        if error == nil {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.AdventuringUsers[index].append(fetchedUser)
                                if self.AdventuringUsers[index].count == usersAttending?.count {
                                    self.reloadCollectionView()
                                }
                            })
                        }
                    })
                })
            }
        } else {
            reloadCollectionView()
        }
    }
    
    /** Handler for reloading all collection views. */
    func reloadCollectionView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.totalServerResponses -= 1
            if self.totalServerResponses == 0 {
                UIView.transitionWithView(self.AdventuringUsersCollectionView, duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                    self.AdventuringUsersCollectionView.reloadData()
                    }, completion: { (action) in self.usersLoadingIndicator.stopAnimating()})
            }
        }
    }
    
    /** Sets the request to attend button titles. */
    func setRequestButton(records: [CKRecord]) {
        if denyRequest(records[0], keywords: "User_Requesting") {
            moveToMainQueueAndSetRequestButton("Pending...")
        } else if denyRequest(records[0], keywords: "User_Attending") {
            moveToMainQueueAndSetRequestButton("Attending")
        } else if denyRequest(records[0], keywords: "User_Host") {
            moveToMainQueueAndSetRequestButton("Hosting")
        }
    }
    
    /** Moves back to the main queue and sets the button title, alpha and disables it. */
    func moveToMainQueueAndSetRequestButton(newTitle: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.scrollView.delegate = nil
            self.requestToAttendButton.enabled = false
            self.requestToAttendButton.alpha = 0.5
            self.requestToAttendButton.setTitle(newTitle, forState: UIControlState.Normal)
        }
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        adjustBackground()
    }
    
    /** Adjusts the background. */
    func adjustBackground() {
        dispatch_async(dispatch_get_main_queue()) {
            self.goeUtilities.setObjectHeight(self.descriptionText, padding: 20)
            self.goeUtilities.setObjectHeight(self.equipment, padding: 8)
            self.goeUtilities.setObjectHeight(self.estimatedCost, padding: 8)
            self.goeUtilities.setBackgroundSize(CGFloat(self.requestToAttendButton.layer.visibleRect.height))
        }
    }
    
    //MARK: Request attendance
    
    @IBAction func RequestAttendance(sender: UIButton) {
        let confirmingRequest = UIAlertController(title: "Request Attendance?", message: "Are you sure you want to attend this adventure? You cannot cancel your request afterwards.", preferredStyle: UIAlertControllerStyle.Alert)
        confirmingRequest.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Destructive, handler: nil))
        confirmingRequest.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action in self.updateCurrentAdventure(self.performQueryToGetUser) }))
        self.presentViewController(confirmingRequest, animated: true, completion: nil)
    }
    
    /** Updates the current adventure before letting the user request attendance to it. */
    func updateCurrentAdventure(completionHandler: () -> ()) {
        showIndicator()
        publicDatabase.fetchRecordWithID((Adventure?.recordID)!) { (fetchedRecord, error) in
            if error == nil {
                self.Adventure = fetchedRecord!
                completionHandler()
            } else {
                print("Error in retrieving ")
            }
        }
    }
    
    @nonobjc func performQueryToGetUser() {
        performQueryToGetUser(doubleCheckCanRequest)
    }
    
    /** Goes and fetches the logged in user. */
    func performQueryToGetUser(completionHandler: ([CKRecord]) -> ()) {
        let tempLoggedInUser = goeCoreData.retrieveData("User")
        let loggedInUser = tempLoggedInUser![0] as? User
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "ID = '\((loggedInUser?.user_ID)!)'"))
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            self.goeUtilities.checkUserBio(records![0])
            self.loggedInUser = records![0]
            completionHandler(records!)
        }
    }
    
    /** Switches the alert to an indicator to show background activity. */
    func showIndicator() {
        waitingForResult = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        globalIndicator = UIActivityIndicatorView(frame: waitingForResult.view.bounds)
        globalIndicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        globalIndicator.color = UIColor.blackColor()
        waitingForResult.view.addSubview(globalIndicator)
        globalIndicator.userInteractionEnabled = false
        globalIndicator.startAnimating()
        self.presentViewController(waitingForResult, animated: true, completion: nil)
    }
    
    /** Checker function to see if user can request attendance. */
    func doubleCheckCanRequest(records: [CKRecord]) {
        if denyRequest(records[0], keywords: "User_Requesting") {
            errorAlert("You have already requested to attend this adventure.")
        } else if denyRequest(records[0], keywords: "User_Attending") {
            errorAlert("You are already attending this adventure.")
        } else if denyRequest(records[0], keywords: "User_Host") {
            errorAlert("You are hosting this adventure.")
        } else if checkUserStatus() {
            errorAlert("You have been blocked from Goe. Please contact support at support@goeadventure.com if you think this is a mistake.")
        }else {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), {
                if EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.Authorized {
                    self.addEventToCalendar()
                }
                self.addCurrentUserToUsersRequestingAttendanceList(records)
            })
        }
    }
    
    /** Should deny request of user based on keywords.*/
    func denyRequest(user: CKRecord, keywords: String) -> Bool{
        if let usersRequesting = Adventure![keywords] as? [CKReference] {
            if usersRequesting.contains(CKReference(record: user, action: CKReferenceAction.None)) {
                return true
            }
        } else if let usersRequesting2 = Adventure![keywords] as? CKReference {
            if usersRequesting2.recordID == user.recordID {
                return true
            }
        }
        return false
    }
    
    /** Checks that the user isn't blocked. */
    func checkUserStatus() -> Bool {
        if loggedInUser != nil {
            if (loggedInUser!["Status"] as? Int) == 666 {
                return true
            }
        }
        return false
    }
    
    /** Displays the error alert if user cannot request attendance. */
    func errorAlert(error: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.waitingForResult = UIAlertController(title: "Failed To Request Attendance", message: error, preferredStyle: UIAlertControllerStyle.Alert)
            self.waitingForResult.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Destructive, handler: { action in self.popController()} ))
            self.dismissViewControllerAnimated(false, completion: nil)
            self.presentViewController(self.waitingForResult, animated: true, completion: nil)
        }
    }
    
    /** Add adventure to the user's calendar.*/
    func addEventToCalendar() {
        let calendar = EKEventStore.init()
        let newItem = EKEvent(eventStore: calendar)
        newItem.title = "goe Adventure: " + (Adventure?.valueForKey("Name") as! String)
        newItem.startDate = Adventure?.valueForKey("Start_Date") as! NSDate
        newItem.endDate = Adventure?.valueForKey("End_Date") as! NSDate
        let startDate = Adventure?.valueForKey("Start_Date") as! NSDate
        let firstAlarm = startDate.dateByAddingTimeInterval(-60*60*Time_Constants.User.HOURS_BEFORE_FIRST_REMINDER)
        let secondAlarm = startDate.dateByAddingTimeInterval(-60*60*Time_Constants.User.HOURS_BEFORE_SECOND_REMINDER)
        newItem.alarms = [EKAlarm(absoluteDate: firstAlarm), EKAlarm(absoluteDate: secondAlarm)]
        newItem.notes = "This adventure has not been confirmed."
        newItem.calendar = calendar.defaultCalendarForNewEvents
        do{
            try calendar.saveEvent(newItem, span: EKSpan.ThisEvent)
        }
        catch _ {
            print("Error Occurred!")
            //handle error
        }
    }
    
    /** Adds the current user to the requesting list.*/
    func addCurrentUserToUsersRequestingAttendanceList(records: [CKRecord]) {
        let newUserRequesting = CKReference(record: records[0], action: CKReferenceAction.None)
        var currentUsersRequesting = Adventure!["User_Requesting"] as? [CKReference] ?? []
        currentUsersRequesting.append(newUserRequesting)
        Adventure!["User_Requesting"] = currentUsersRequesting
        self.publicDatabase.saveRecord(self.Adventure!, completionHandler: { (savedAdventure, error) -> Void in
            if error != nil {
                print("Adventure View Details throwing: \(error)")
                //handle error here
            } else {
                self.globalIndicator.stopAnimating()
                if EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.Authorized {
                    self.waitingForResult = UIAlertController(title: "Successfully Requested", message: "This event has also been temporarily added to your calendar.", preferredStyle: UIAlertControllerStyle.Alert)
                } else {
                    self.waitingForResult = UIAlertController(title: "Successfully Requested", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                }
                self.waitingForResult.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler: { action in self.popController()} ))
                dispatch_async(dispatch_get_main_queue(), {
                    self.dismissViewControllerAnimated(false, completion: nil)
                    self.presentViewController(self.waitingForResult, animated: true, completion: nil)
                })
            }
        })
    }
    
    /** Pops the current view controller.*/
    func popController(){
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    //MARK: Scrollview Delegate Methods
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        requestToAttendButton.alpha = CGFloat(0.25)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        requestToAttendButton.alpha = CGFloat(1.0)
    }
    
    
    //MARK: Collection View Delegate Items
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return AdventuringUsers.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AdventuringUsers[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = AdventuringUsersCollectionView.dequeueReusableCellWithReuseIdentifier("UserCell", forIndexPath: indexPath) as! UserCell
        dispatch_async(dispatch_get_main_queue()) {
            let name = self.AdventuringUsers[indexPath.section][indexPath.row]!.valueForKey("Name") as? String
            let tempTitle = name!.characters.split{$0 == "."}.map(String.init)
            cell.Name.text = tempTitle[0]
            let tempProfilePicData = self.goeCloudData.getProfilePhoto(self.AdventuringUsers[indexPath.section][indexPath.row]!)
            if tempProfilePicData != nil {
                cell.ProfilePicture.image = UIImage(data: tempProfilePicData!)
            }
            let host_reference = (self.Adventure?.valueForKey("User_Host") as? CKReference)?.recordID.recordName
            let curr_user = (self.AdventuringUsers[indexPath.section][indexPath.row])?.recordID.recordName
            if (host_reference == curr_user) {
                cell.host.text = "Host"
            } else {
                cell.host.text = ""
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedUser = AdventuringUsers[indexPath.section][indexPath.row]
        self.performSegueWithIdentifier("ShowUserDetail", sender: self)
    }
    
    //MARK: Segue preparation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is AdventureUserDetailViewController {
            let destination = segue.destinationViewController as? AdventureUserDetailViewController
            destination?.viewingUserDetail = selectedUser
        }
    }
}
