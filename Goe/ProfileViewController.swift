//
//  ProfileViewController.swift
//  Goe
//
//  Created by Kadhir M on 1/15/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import Foundation
import EventKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CAAnimationDelegate {

    //MARK: IBOutlets
    
    /** The profile name.*/
    @IBOutlet weak var profileName: UILabel!
    /** The profile picture of the user.*/
    @IBOutlet weak var profilePicture: UIImageView!
    /** The goe rating of the user.*/
    @IBOutlet weak var GoeRating: UILabel!
    /** Scrollview background.*/
    @IBOutlet weak var scrollViewBackground: UIScrollView!
    /** The user's biography text.*/
    @IBOutlet weak var Bio: UILabel!
    /** The user's adventures table view.*/
    @IBOutlet weak var adventuresTableView: UITableView!
    /** The blurred out background picture.*/
    @IBOutlet weak var backgroundProfilePicture: UIImageView!
    /** Refresh button.*/
    @IBOutlet weak var refreshButton: UIButton!

    //MARK: Utility Helpers
    
    /** Goe core data helper.*/
    let goeCoreData = GoeCoreData()
    /** Goe cloud data helper.*/
    let goeCloudData = GoeCloudKit()
    /** The goe utilities helper. */
    var goeUtilities = GoeUtilities()
    /** Public database assistant.*/
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    //MARK: Profile specific Variables
    
    /** When the viewappears and the view needs to be force reloaded, set to true.*/
    var forceReload = false
    /** If the user needs to set his/her bio. */
    var forceSetBio = false
    /** Lets the system know if it needs to check for the bio once it's loaded. */
    var checkBio = false
    /** If true, profile is refreshing. */
    var currentlyRefreshing = false
    /** The current logged in Core Data user.*/
    var loggedInUser: User?
    /** Logged in user's CKRecord.*/
    var loggedInUserCloudDetails: CKRecord?
    /** Logged in user's profile CKRecord.*/
    var loggedInUserCloudProfile: CKRecord?
    /** The calendar instantiation.*/
    let calendar = EKEventStore.init()
    /** Should the refresh indicator stop rotating.*/
    var shouldStopRotating = false
    /** If the indicator is rotating, will be true.*/
    var isRotating = false
    /** Total UI items to load.*/
    var totalUILoaded = 3
    
    //MARK: Profile Adventure Variables
    
    /** All the adventures in a user's profile.*/
    var allAdventures2 = [[CKRecord]]()
    /** All attending adventures.*/
    var attendingAdventures: [CKRecord] = []
    /** All hosting adventures.*/
    var hostingAdventures: [CKRecord] = []
    /** All adventures recently rejected from.*/
    var recentlyRejectedFromAdventures: [CKRecord] = []
    /** All adventures recently completed.*/
    var recentlyCompletedAdventures: [CKRecord] = []
    /** All adventures in history.*/
    var adventureHistory: [CKRecord] = []
    /** The cell selected to segue.*/
    var selectedCell: CKRecord?
    /** Total number of items to load in this profile view.*/
    var totalNumLoaded = 5
    /** All header titles.*/
    let headerTitles = ["Hosting", "Attending", "Unavailable", "To Rate", "History"]
    /** Equivalent to headerTitles, except these are cloudkit database titles.*/
    let databaseTitles = ["Adventure_Hosting", "Adventure_Attending", "Adventure_Rejected", "Adventure_Completed", "Adventure_History"]
    
    //MARK: Methods Begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tempLoggedInUser = self.goeCoreData.retrieveData("User")
        self.loggedInUser = tempLoggedInUser![0] as? User
        self.setProfileAttributes()
        self.registerHeaders()
        self.refreshProfileView(self)
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: self.scrollViewBackground)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshProfileView), name: "goeBecameActive", object: nil)
    }
    
    /** Sets the profile picture, background picture and user name.*/
    func setProfileAttributes(){
        dispatch_async(dispatch_get_main_queue()) {
            /* Setting the profile picture and making it into a circle. */
            self.profilePicture.image = UIImage(data: (self.loggedInUser?.picture)!)
            self.profilePicture.layer.borderWidth = 3
            self.profilePicture.layer.borderColor = ColorConstants.Profile.profilePictureBorderColor
            self.profilePicture.layer.masksToBounds = false
            self.profilePicture.layer.cornerRadius = self.profilePicture.frame.height/2
            self.profilePicture.clipsToBounds = true
        }
        
        /* Setting the background image and creating the blur effect. */
        for view in self.backgroundProfilePicture.subviews {
            view.removeFromSuperview()
        }
        self.backgroundProfilePicture.image = UIImage(data: (self.loggedInUser?.picture)!)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = backgroundProfilePicture.frame
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.backgroundProfilePicture.addSubview(blurEffectView)
        
        /* Setting the profile name. */
        self.profileName.text = goeUtilities.splitUserName((self.loggedInUser?.user_Name)!)
    }
    
    /** Registers the table view headerss.*/
    func registerHeaders(){
        let nib = UINib(nibName: "ProfileTableHeader", bundle: nil)
        adventuresTableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "ProfileTableHeader")
    }
    
    //MARK: Refresh Profile View
    
    /** Refreshes the profile view by fetching the user profile.*/
    func refreshProfileView(sender: AnyObject?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.adventuresTableView.userInteractionEnabled = false
            self.refreshButton.alpha = CGFloat(1)
            self.refreshButton.rotate360Degrees(completionDelegate: self)
            self.isRotating = true
        }
        totalNumLoaded = self.databaseTitles.count
        goeCloudData.fetchProfile((loggedInUser?.user_ID)!, completionHandler: adjustTables)
        self.getUserDetails((self.loggedInUser?.user_ID))
    }
    
    /** Given a user's ID, will fetch the user's CKRecord.*/
    func getUserDetails(userID: String?) {
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "ID = '\((userID)!)' "))
        publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            if (error == nil && records?.count > 0) {
                self.loggedInUserCloudDetails = records![0]
                self.setUserCloudParameters()
            } else {
                if records?.count > 0 {
                    print("Loading User error: \(error)")
                } else {
                    self.goeUtilities.logout(self)
                }
            }
        }
    }
    
    /** Sets the bio and rating of the user.*/
    func setUserCloudParameters() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.loggedInUserCloudDetails != nil {
                if (self.loggedInUserCloudDetails!["Status"] as? Int == 666) {
                    self.performSegueWithIdentifier("Blocked", sender: self)
                }
                let GoeCloudRating = (self.loggedInUserCloudDetails!.valueForKey("Goe_Rating"))!
                UIView.transitionWithView(self.GoeRating, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                    self.GoeRating.text = "Goe Rating: \(GoeCloudRating)"
                    }, completion: nil)
                if let userDetails = (self.loggedInUserCloudDetails!.valueForKey("Details")) as? [String] {
                    if self.Bio.text != userDetails[0] {
                        UIView.transitionWithView(self.Bio, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                            NSLayoutConstraint.deactivateConstraints(self.Bio.constraints)
                            self.Bio.text = userDetails[0] ?? "None"
                            self.Bio.sizeToFit()
                            let height = (self.Bio.frame.height) * 1.1
                            NSLayoutConstraint.deactivateConstraints(self.Bio.constraints)
                            let newConstraint = NSLayoutConstraint(item: self.Bio, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: height)
                            NSLayoutConstraint.activateConstraints([newConstraint])
                            self.Bio.frame = CGRect(origin: self.Bio.frame.origin, size: CGSize(width: self.view.frame.height, height: height))
                            }, completion: nil )
                    }
                }
                self.forceReload = false
                if self.checkBio {
                    self.goeUtilities.checkUserBio(self.loggedInUserCloudDetails!, completionHandler: { self.performSegueWithIdentifier("Edit", sender: self) })
                }
            }
            self.setBackgroundSize()
        })
    }
    
    /** Resizes the scrollview to fit the exact size of its content.*/
    func setBackgroundSize(){
        dispatch_async(dispatch_get_main_queue()) {
            self.totalUILoaded -= 1
            if self.totalUILoaded == 0 {
                var contentRect = CGRectZero
                for view in self.scrollViewBackground.subviews {
                    contentRect = CGRectUnion(contentRect, view.frame)
                }
                self.scrollViewBackground.contentSize = CGSize(width: self.view.frame.width, height: contentRect.height)
                self.totalUILoaded = 3
            }
        }
    }

    /** Fetches all adventures of the user.*/
    func adjustTables(loggedInUserProfile: CKRecord?) {
        loggedInUserCloudProfile = loggedInUserProfile
        clearOutArrays()
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            for index in 0...(self.databaseTitles.count - 1) {
                self.fetchAdventures(self.databaseTitles[index], arrayIndex: index, completionHandler: self.reloadTable)
            }
        }
    }
    
    /** Clears out all the arrays of adventures.*/
    func clearOutArrays(){
        allAdventures2.removeAll()
        hostingAdventures.removeAll()
        attendingAdventures.removeAll()
        recentlyRejectedFromAdventures.removeAll()
        recentlyCompletedAdventures.removeAll()
        adventureHistory.removeAll()
        allAdventures2.append(hostingAdventures)
        allAdventures2.append(attendingAdventures)
        allAdventures2.append(recentlyRejectedFromAdventures)
        allAdventures2.append(recentlyCompletedAdventures)
        allAdventures2.append(adventureHistory)
    }
    
    /** Fetches the adventure specified. */
    func fetchAdventures(keywords: String, arrayIndex: Int, completionHandler: () -> Void) {
        let adventuresInQuestion = loggedInUserCloudProfile?.valueForKey("\(keywords)") as? [CKReference] ?? []
        if adventuresInQuestion.count > 0 {
            var totalCountNeeded = adventuresInQuestion.count
            for adventure in adventuresInQuestion {
                self.publicDatabase.fetchRecordWithID(adventure.recordID) { fetchedAdventure, error in
                    if error == nil {
                        if fetchedAdventure != nil {
                            self.allAdventures2[arrayIndex].append(fetchedAdventure!)
                            if self.allAdventures2[arrayIndex].count == totalCountNeeded {
                                completionHandler()
                            }
                        } else {
                            totalCountNeeded -= 1
                        }
                    } else {
                        print("Appending adventure error: \(error)")
                    }
                }
            }
        } else {
            completionHandler()
        }
    }
    
    /** Reloads the tableview once all the server responses comes back. */
    func reloadTable(){
        dispatch_async(dispatch_get_main_queue(), {
            self.totalNumLoaded -= 1
            if self.totalNumLoaded == 0 {
                self.currentlyRefreshing = false
                self.hideOrDisplayTableView()
                self.changeSizes()
                self.stopRefreshing()
                self.checkForCompletedAdventures()
                self.checkAndClearSubscriptions()
                self.adventuresTableView.userInteractionEnabled = true
            }
        })
    }
    
    /** Changes the height of the adventures tableview.*/
    func changeSizes() {
        NSLayoutConstraint.deactivateConstraints(self.adventuresTableView.constraints)
        UIView.transitionWithView(self.adventuresTableView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.adventuresTableView.reloadData()
            }, completion: nil)
        self.adventuresTableView.sizeToFit()
        let height = self.adventuresTableView.contentSize.height
        let newConstraint = NSLayoutConstraint(item: self.adventuresTableView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: height)
        NSLayoutConstraint.activateConstraints([newConstraint])
        setBackgroundSize()
    }
    
    /** Checks for completed adventures. */
    func checkForCompletedAdventures(){
        var itemsDidChange = false
        var mainArrayIndex = 0
        var subArrayIndex = 0
        let date = NSDate()
        for adventure_type in allAdventures2 {
            subArrayIndex = 0
            for adventure in adventure_type {
                let date_diff = adventure.valueForKey("End_Date") as? NSDate
                if date_diff!.compare(date).rawValue != 1 {
                    itemsDidChange = true
                    allAdventures2[3].append(adventure)
                    allAdventures2[mainArrayIndex].removeAtIndex(subArrayIndex)
                } else {
                    subArrayIndex += 1
                }
            }
            mainArrayIndex += 1
            if mainArrayIndex == 2 {
                break
            }
        }
        if itemsDidChange {
            updateCloudProfile()
        } else if allAdventures2[3].count > 0 {
            changeSizes()
            askForRatings()
        }
    }
    
    /** Updates the adventure cloud profile by saving all current adventures first.*/
    func updateCloudProfile() {
        loggedInUserCloudProfile!["Adventure_Hosting"] = createCKReferenceList(0)
        loggedInUserCloudProfile!["Adventure_Attending"] = createCKReferenceList(1)
        loggedInUserCloudProfile!["Adventure_Completed"] = createCKReferenceList(3)
        goeCloudData.saveRecord(loggedInUserCloudProfile!, completionHandler: refreshProfileView)
    }
    
    /** Creates a CKReference list with all the adventures.*/
    func createCKReferenceList(indexArray: Int) -> [CKReference] {
        var allIndexedAdventures = [CKReference]()
        for adventure in allAdventures2[indexArray] {
            let tempAdventure = CKReference(recordID: adventure.recordID, action: CKReferenceAction.None)
            allIndexedAdventures.append(tempAdventure)
        }
        return allIndexedAdventures
    }
    
    /** Presents a alert to ask for the adventure rating.*/
    func askForRatings() {
        var changeSelectedCell = true
        for adventure in allAdventures2[3] {
            let adventureName = adventure.valueForKey("Name")
            let completedRequest = UIAlertController(title: "Please Rate This Adventure", message: "Let the community know how \(adventureName!) went!", preferredStyle: UIAlertControllerStyle.Alert)
            completedRequest.addAction(UIAlertAction(title: "Rate", style: UIAlertActionStyle.Default, handler: { action in self.performSegueWithIdentifier("To Rate", sender: self) } ))
            completedRequest.addAction(UIAlertAction(title: "Maybe Later", style: UIAlertActionStyle.Destructive, handler: nil ))
            if (self.isViewLoaded() && (self.view.window != nil)) {
                if changeSelectedCell {
                    self.selectedCell = adventure
                    changeSelectedCell = false
                }
                self.presentViewController(completedRequest, animated: true, completion: nil)
            }
        }
    }
    
    /** Stops rotating the refresh button.*/
    func stopRefreshing() {
        if isRotating {
            shouldStopRotating = true
        }
    }
    
    /** Hides or displays the table view with adventures depending on whether or not there are adventures present. */
    func hideOrDisplayTableView() {
        for index in 0...(allAdventures2.count - 1) {
            if allAdventures2[index].count > 0 {
                self.adventuresTableView.hidden = false
                return
            }
        }
        self.adventuresTableView.hidden = true
    }
    
    /** If the user is not attending/hosting/completed any adventures, will go through and clean up their subscriptions. */
    func checkAndClearSubscriptions() {
        if currentlyRefreshing == false {
            for index in 0...1{
                if allAdventures2[index].count > 0 {
                    return
                }
            }
            publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions: [CKSubscription]?, error: NSError?) in
                for subscription in subscriptions! {
                    if ((subscription.recordType != "Profile") && (subscription.predicate != NSPredicate(format: "TRUEPREDICATE"))) {
                        self.publicDatabase.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {_,_ in })
                    }
                }
            }
        }
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if forceSetBio {
            forceSetBio = false
            self.performSegueWithIdentifier("Edit", sender: self)
        } else {
            if self.loggedInUserCloudDetails != nil {
                self.goeUtilities.checkUserBio(self.loggedInUserCloudDetails!, completionHandler: { self.performSegueWithIdentifier("Edit", sender: self) })
            } else {
                checkBio = true
            }
        }
        if EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.NotDetermined {
            requestCalendarAccess()
        }
        if !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            requestNotificationAccess()
        }
        resetBadgeCounter()
        if forceReload {
            goeUtilities.slideToExtreme()
            refreshProfileView(self)
        }
    }
    
    /** Requests calendar access for the user.*/
    func requestCalendarAccess() {
        calendar.requestAccessToEntityType(EKEntityType.Event){_,_ in }
    }
    
    /** Requests notification access.*/
    func requestNotificationAccess(){
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
 
    /** Resets the badge counter to zero.*/
    func resetBadgeCounter() {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: 0)
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                print("Error resetting badge: \(error)")
            }
            else {
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            }
        }
        CKContainer.defaultContainer().addOperation(badgeResetOperation)
    }
    
    //MARK: Refresh
    
    /** Handler for refreshing the profile view.*/
    @IBAction func refresh(sender: UIButton) {
        currentlyRefreshing = true
        refreshProfileView(self)
        setProfileAttributes()
    }
    
    /** When the animating buttons did stop rotating, comes to this handler. */
    func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if (self.shouldStopRotating == false && isRotating == true) {
            self.refreshButton.rotate360Degrees(completionDelegate: self)
        } else {
            self.shouldStopRotating = false
            self.isRotating = false
            self.refreshButton.alpha = CGFloat(0.5)
        }
    }
    
    //MARK: UITABLEVIEW VIEW FUNCTIONS
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return allAdventures2.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if allAdventures2[section].count > 0 {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = headerTitles[section]
        let cell = self.adventuresTableView.dequeueReusableHeaderFooterViewWithIdentifier("ProfileTableHeader") as! ProfileTableHeader
        cell.headerLabel.text = title
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(30)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Adventure Cell",forIndexPath: indexPath) as? ProfileTableViewCell
        cell?.setCollectionViewDataSourceDelegate(self, forHeight: indexPath.section, forRow: indexPath.row)
        return cell!
    }
    
    //Mark: Segue Preparation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let destination = segue.destinationViewController as? EditProfileController{
            if let user_cloud_details = loggedInUserCloudDetails{
                destination.loggedInUserCloudDetails = user_cloud_details
            }
        } else if let destination = segue.destinationViewController as? RateAdventureViewController {
            destination.AdventureToRate = selectedCell
            destination.currentUser = loggedInUserCloudDetails!
            destination.currentUserProfile = loggedInUserCloudProfile!
        } else if let destination = segue.destinationViewController as? HostingAdventureViewController {
            destination.Adventure = selectedCell
        } else if let destination = segue.destinationViewController as? AttendingAdventureViewController {
            destination.Adventure = selectedCell
        }
    }
    
    /** Deletes the selected adventure (selectedCell).*/
    func deleteSelectedAdventure() {
        let top = CGRect(x: 0, y: 0, width: 600, height: 200)
        scrollViewBackground.scrollRectToVisible(top, animated: true)
        self.refreshButton.alpha = CGFloat(1)
        self.refreshButton.rotate360Degrees(completionDelegate: self)
        isRotating = true
        var current_adventures = loggedInUserCloudProfile?.valueForKey("Adventure_Rejected") as! [CKReference]
        var index = 0
        for adventure in current_adventures {
            if adventure.recordID == selectedCell?.recordID {
                current_adventures.removeAtIndex(index)
                break
            }
            index += 1
        }
        loggedInUserCloudProfile!["Adventure_Rejected"] = current_adventures
        goeCloudData.saveRecord(loggedInUserCloudProfile!, completionHandler: removeDeletedAdventure)
    }
    
    /** Removes the deleted adventure by refreshing the profile view. */
    func removeDeletedAdventure(record: CKRecord?) {
        self.stopRefreshing()
        refreshProfileView(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        goeCoreData.clearCaches()
    }
}
