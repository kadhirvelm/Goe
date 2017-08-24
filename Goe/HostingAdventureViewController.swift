//
//  HostingAdventureCellDetail.swift
//  Goe
//
//  Created by Kadhir M on 1/24/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class HostingAdventureViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, GoeMapViewDelegate {
    
    /** REQUIRED VARIABLE. The adventure the user is hosting and this viewcontroller is loading from.*/
    var Adventure: CKRecord?
    
    /** The error text displayed if one of the checks fails.*/
    @IBOutlet weak var errorText: UILabel!
    /** Background scroll view to resize.*/
    @IBOutlet weak var backgroundScrollView: UIScrollView!
    
    //MARK: Adventure specific items
    
    /** All requesting users collection view.*/
    @IBOutlet weak var requestingUsersCollectionView: UICollectionView!
    /** Requesting users UIView holder. */
    @IBOutlet weak var requestingUsersView: UIView!
    /** All attending users collection view.*/
    @IBOutlet weak var attendingUsersCollectionView: UICollectionView!
    /** The adventure title.*/
    @IBOutlet weak var AdventureTitle: UITextField!
    /** The adventure description.*/
    @IBOutlet weak var AdventureDescription: UITextView!
    /** The adventure photo.*/
    @IBOutlet weak var adventurePhoto: UIImageView!
    /** The date of the adventure. */
    @IBOutlet weak var Date: UILabel!
    /** All the open spots on the adventure. */
    @IBOutlet weak var OpenSpots: UILabel!
    /** The expected cost of the adventure.*/
    @IBOutlet weak var expectedCost: UITextView!
    /** All the equipment needed for the adventure.*/
    @IBOutlet weak var equipment: UITextView!
    /** Delete adventure button. */
    @IBOutlet weak var deleteAdventure: UIButton!
    /** Requesting users indicator and button. */
    @IBOutlet weak var requestingUsersButton: UIButton!
    /** Specific category. */
    @IBOutlet weak var category: UILabel!
    /** Company logo. */
    @IBOutlet weak var companyLogo: UIImageView!
    
    //MARK: Non-adventure specific items
    
    /** For increasing and decreasing number of open spots in the adventure.*/
    @IBOutlet weak var stepper: UIStepper!
    /** The settings/save icon in the upper right hand corner.*/
    @IBOutlet weak var barButton: UIBarButtonItem!
    /** Indicator that the attending users are loading. */
    @IBOutlet weak var attendingUsersLoading: UIActivityIndicatorView!
    /** No attending users label.*/
    @IBOutlet weak var attendingUsersLabel: UILabel!
    /** Indicator that the requesting users are loading. */
    @IBOutlet weak var requestingUsersLoading: UIActivityIndicatorView!
    
    //MARK: Utility variables
    
    /** Accesses the public database of records. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    /** Goe utility helper class, for cloudkit. */
    let goeCloudData = GoeCloudKit()
    /** Goe location helper. */
    let goeLocationHelper = GoeCoreLocationHelper()
    /** addressChecker regex functionality.*/
    let addressChecker = Regex()
    /** Utilties helper function. */
    var goeUtilities = GoeUtilities()
    /** Goe Map container delegate holder. */
    var goeMapDelegate: GoeMapContainerDelegate?
    
    //MARK: Functionality variables
    
    /** All user details for users requesting attendance to the adventure.*/
    var usersRequesting: [CKRecord?] = []
    /** All users details for who are attending the adventure.*/
    var attendingUsers: [CKRecord?] = []
    /** If a requesting users is selected, will populate here.*/
    var accept_denyUser: CKRecord?
    /** If an attending user is selected, will populate here.*/
    var selected_user: CKRecord?
    /** The final destination location. */
    var destinationAddress: CLLocation?
    /** The final destination string. */
    var destinationString: String?
    /** The final origin location .*/
    var rendezvousAddress: CLLocation?
    /** The final destination string. */
    var rendezvousString: String?
    /** Dismissing requesting users view. */
    var dismissRequestingUsersTapRecognizer: UITapGestureRecognizer?
    
    //MARK: UI Functionality variables
    
    /** The alert controller that alerts the user when an action is selected.*/
    var confirmRequest = UIAlertController()
    /** The indicator that the adventure is currently being acted upon.*/
    var indicator = UIActivityIndicatorView()
    /** Will be true if the user is currently editing the adventure.*/
    var currentlyEditing = false
    /** The open spots left in this adventure.*/
    var openSpotsInt = 0
    
    //MARK: Methods begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissRequestingUsersTapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(HostingAdventureViewController.dismissRequestingUsers))
        requestingUsersView.alpha = 0
        self.setAdventureDetails()
        self.setUsersRequestingAttendance()
        self.setAttendingUsers()
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: self.backgroundScrollView)
        self.goeUtilities.setKeyboardObservers()
    }
    
    /** Sets all the adventure details in the UI.*/
    func setAdventureDetails(){
        dispatch_async(dispatch_get_main_queue()) {
            self.AdventureTitle.text = self.Adventure?.valueForKey("Name") as? String
            self.AdventureDescription.text = self.Adventure?.valueForKey("Description") as? String
            let imageData = self.goeCloudData.getAdventurePhoto(self.Adventure!)
            if imageData != nil {
                self.adventurePhoto.image = UIImage(data: imageData!)
            }
            let startDate = NSDateFormatter.localizedStringFromDate((self.Adventure?.valueForKey("Start_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
            let endDate = NSDateFormatter.localizedStringFromDate((self.Adventure?.valueForKey("End_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
            self.Date.text = "\(startDate) - \(endDate)"
            self.openSpotsInt = (self.Adventure?.valueForKey("Spots") as! Int)
            self.OpenSpots.text = "Open Spots: \(self.openSpotsInt)"
            self.stepper.value = Double(self.openSpotsInt)
            self.expectedCost.text = self.Adventure?.valueForKey("Estimated_Cost") as! String
            self.equipment.text = self.Adventure?.valueForKey("Equipment") as! String
            self.category.text = self.Adventure?.valueForKey("Category") as? String
            let logo = self.Adventure?.valueForKey("Logo") as? CKAsset
            if logo != nil {
                let logo = self.goeCloudData.changeAssetToImage(logo!)
                if logo != nil {
                    self.companyLogo?.image = logo!
                }
            }
            self.adjustSizes()
        }
    }
    
    /** Adjusts the sizes of the description, equipment, and background.*/
    func adjustSizes() {
        self.goeUtilities.setObjectHeight(self.AdventureDescription, padding: 0)
        self.goeUtilities.setObjectHeight(self.equipment, padding: 8)
        self.goeUtilities.setBackgroundSize()
    }
    
    /** Goes through and populates the usersRequesting array with all the requesting users.*/
    func setUsersRequestingAttendance() {
        usersRequesting.removeAll()
        let usersRequestingReference = Adventure?.valueForKey("User_Requesting") as? [CKReference] ?? []
        if usersRequestingReference.count > 0 {
            setRequestingUsersNotification(usersRequestingReference.count)
            for user in usersRequestingReference {
                self.publicDatabase.fetchRecordWithID(user.recordID) { fetchedUser, error in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.usersRequesting.append(fetchedUser)
                        if self.usersRequesting.count == usersRequestingReference.count {
                            self.requestingUsersLoading.stopAnimating()
                            self.fadeInCollectionView(self.requestingUsersCollectionView)
                        }
                    })
                }
            }
        } else {
            requestingUsersLoading.stopAnimating()
        }
    }
    
    /** Sets the colors and text for requesting users.*/
    func setRequestingUsersNotification(totalCount: Int) {
        if totalCount > 0 {
            requestingUsersButton.enabled = true
        } else {
            requestingUsersButton.enabled = false
        }
        requestingUsersButton.setTitle("\(totalCount) Requesters", forState: UIControlState.Normal)
        requestingUsersButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        requestingUsersButton.backgroundColor = UIColorFromHex(0xFF2D2D)
    }
    
    /** Goes through and populates the attendingUsers array with all the attending users.*/
    func setAttendingUsers() {
        attendingUsers.removeAll()
        let usersAttending = Adventure?.valueForKey("User_Attending") as? [CKReference] ?? []
        if usersAttending.count > 0 {
            for user in usersAttending {
                self.publicDatabase.fetchRecordWithID(user.recordID) { fetchedUser, error in
                    dispatch_async(dispatch_get_main_queue(), {
                        self.attendingUsers.append(fetchedUser)
                        if self.attendingUsers.count == usersAttending.count {
                            self.attendingUsersLoading.stopAnimating()
                            self.fadeInCollectionView(self.attendingUsersCollectionView)
                        }
                    })
                }
            }
        } else {
            self.attendingUsersLoading.stopAnimating()
            attendingUsersCollectionView.hidden = true
            attendingUsersLabel.hidden = false
        }
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        setMapItems()
    }
    
    /** Given the map delegate, will go through and set the proper parameters for the map. */
    func setMapItems() {
        self.destinationString = self.Adventure?.valueForKey("String_Destination") as? String
        self.destinationAddress = self.Adventure?.valueForKey("Destination") as? CLLocation
        self.goeMapDelegate!.mapDestination(destinationString!, coordinates: self.destinationAddress!, textEntryEnabled: true)
        self.rendezvousString = self.Adventure?.valueForKey("String_Origin") as? String
        self.rendezvousAddress = self.Adventure?.valueForKey("Origin") as? CLLocation
        self.goeMapDelegate!.mapRendezvous(rendezvousString!, coordinates: self.rendezvousAddress!, textEntryEnabled: true)
        self.goeMapDelegate?.enableEditing(false)
    }
    
    /** Toggles between a view only mode and an edit mode.*/
    @IBAction func changeEditable(sender: UIBarButtonItem) {
        let checks = [checkOrigin(), checkDestination(), checkDescription(), checkOpenSpots(), checkTitle()]
        if !checks.contains(false) {
            currentlyEditing = !currentlyEditing
            if currentlyEditing {
                self.barButton.image = UIImage(named: "Save_25x25")
                stepper.alpha = CGFloat(1)
                AdventureTitle.borderStyle = UITextBorderStyle.RoundedRect
                AdventureTitle.backgroundColor = UIColorFromHex(0x7F7F7F)
            } else {
                self.barButton.image = UIImage(named: "Settings Filled")
                stepper.alpha = CGFloat(0)
                AdventureTitle.borderStyle = UITextBorderStyle.None
                AdventureTitle.backgroundColor = UIColor.clearColor()
                if needsSaving() {
                    checkForAdventureHistory()
                    save()
                }
            }
            goeMapDelegate?.enableEditing(currentlyEditing)
            stepper.enabled = currentlyEditing
            AdventureTitle.enabled = currentlyEditing
            AdventureDescription.editable = currentlyEditing
            expectedCost.editable = currentlyEditing
            equipment.editable = currentlyEditing
            deleteAdventure.hidden = !currentlyEditing
        }
    }
    
    /** Returns whether or not the current adventure needs to be saved. */
    func needsSaving() -> Bool {
        var needSave = false
        let tempAdventure = Adventure?.copy() as! CKRecord
        Adventure?["Name"] = AdventureTitle.text
        Adventure?["Description"] = AdventureDescription.text
        Adventure?["Spots"] = openSpotsInt
        Adventure?["Destination"] = destinationAddress
        Adventure?["String_Destination"] = destinationString
        Adventure?["Origin"] = rendezvousAddress
        Adventure?["String_Origin"] = rendezvousString
        Adventure?["Estimated_Cost"] = expectedCost.text
        Adventure?["Equipment"] = equipment.text
        for key in tempAdventure.allKeys() {
            if needSave == false {
                needSave = !(tempAdventure[key]!.isEqual(Adventure![key]))
            } else {
                break
            }
        }
        return needSave
    }
    
    /** Checks if this adventure has an adventure history, and appends this user to the attending users list. */
    func checkForAdventureHistory() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let id = (self.Adventure!["ID"] as? Int)!
            let predicate = NSPredicate(format: "ID = \(id)")
            let query = CKQuery(recordType: "Adventure_History", predicate: predicate)
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if error == nil {
                    if records?.count > 0{
                        self.updateAdventureHistory(records![0])
                    }
                } else {
                    print("Adventure history error: \(error)")
                }
            }
        })
    }
    
    /** Updates the adventure history will all the items in the newly edited adventure. */
    func updateAdventureHistory(adventureHistory: CKRecord) {
        adventureHistory["Description"] = Adventure!["Description"] as? String
        adventureHistory["Name"] = Adventure!["Name"] as? String
        adventureHistory["Start_Date"] = Adventure!["Start_Date"] as? NSDate
        adventureHistory["End_Date"] = Adventure!["End_Date"] as? NSDate
        adventureHistory["Equipment"] = Adventure!["Equipment"] as? String
        adventureHistory["Estimated_Cost"] = Adventure!["Estimated_Cost"] as? String
        adventureHistory["Origin"] = Adventure!["Origin"] as? CLLocation
        adventureHistory["Destination"] = Adventure!["Destination"] as? CLLocation
        goeCloudData.saveRecord(adventureHistory)
    }
    
    /** Saves the current adventure details in the cloud. */
    func save() {
        goeCloudData.saveRecord(Adventure!, completionHandler: handleSaveResponse)
        confirmRequest = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        indicator = UIActivityIndicatorView(frame: self.confirmRequest.view.bounds)
        self.indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.indicator.color = UIColor.redColor()
        self.confirmRequest.view.addSubview(self.indicator)
        self.indicator.userInteractionEnabled = false
        self.indicator.startAnimating()
        self.presentViewController(confirmRequest, animated: true, completion: nil)
    }
    
    /** Handles the sever response once saving has finished. */
    func handleSaveResponse(savedRecord: CKRecord?) {
        dispatch_async(dispatch_get_main_queue()) {
            if savedRecord != nil {
                self.confirmRequest.title = "Successfully Updated"
            } else {
                self.confirmRequest.title = "Error"
                self.confirmRequest.message = "There was an error updating the adventure"
            }
            self.indicator.stopAnimating()
            self.confirmRequest.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { action in self.goeUtilities.segueAndForceReloadProfileViewController()}))
            self.dismissViewControllerAnimated(false) {
                self.presentViewController(self.confirmRequest, animated: true, completion: nil)
            }
        }
    }
    
    /** Increases or decreases the number of open spots. */
    @IBAction func increment(sender: UIStepper) {
        openSpotsInt = Int(sender.value)
        OpenSpots.text = "Open Spots: \(openSpotsInt)"
    }
    
    /** Once clicked, scrolls down to the chat box. */
    @IBAction func scrollToChat(sender: UIButton) {
        goeUtilities.slideToExtreme(false)
    }
    
    //MARK: Checker functions
    
    func checkTitle() -> Bool {
        if AdventureTitle.text == "Adventure Title" {
            errorText.text = "Don't forget to set your adventure title."
            return false
        } else if AdventureTitle.text == "" {
            errorText.text = "Must have an adventure title."
            return false
        } else {
            errorText.text = ""
            return true
        }
    }
    
    func checkOpenSpots() -> Bool {
        if openSpotsInt >= 0 {
            errorText.text = ""
            return true
        } else {
            errorText.text = "You must have 0 or more spots."
            return false
        }
    }
    
    func checkDescription() -> Bool {
        if AdventureDescription.text == "Adventure Description" {
            errorText.text = "Please set your adventure description."
            return false
        } else if AdventureDescription.text == "" {
            errorText.text = "You must have an adventure description."
            return false
        } else {
            errorText.text = ""
            return true
        }
    }
    
    func checkDestination() -> Bool {
        if destinationAddress == nil {
            errorText.text = "Invalid destination address. Must be a proper postal address."
            return false
        } else {
            return true
        }
    }
    
    func checkOrigin() -> Bool {
        if rendezvousAddress == nil {
            errorText.text = "Invalid rendezvous address. Must be a proper postal address."
            return false
        } else {
            return true
        }
    }
    
    /** Handles the done button of the uitextfield .*/
    @IBAction func resign(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    //MARK: Requesting Handler
    
    /** Handles the dismissing and presenting of the requesting users view.*/
    @IBAction func requestingUsers(sender: UIButton) {
        changeRequestingUsersView()
        backgroundScrollView.addGestureRecognizer(dismissRequestingUsersTapRecognizer!)
    }
    
    /** Changes the requesting users view to the opposite of its current state. */
    func changeRequestingUsersView() {
        self.view.bringSubviewToFront(requestingUsersView)
        requestingUsersView.hidden = !self.requestingUsersView.hidden
        UIView.transitionWithView(requestingUsersButton, duration: 0.18, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.requestingUsersView.alpha = (self.requestingUsersView.hidden ? 0:1)
            }, completion: nil)
    }
    
    /** Dismisses the requesting users view witha single tap gesture.*/
    func dismissRequestingUsers(sender: UITapGestureRecognizer) {
        changeRequestingUsersView()
        backgroundScrollView.removeGestureRecognizer(dismissRequestingUsersTapRecognizer!)
    }
    
    //MARK: MapView Delegate methods
    
    func destinationResponse(title: String, address: String, coordinates: CLLocation) {
        destinationAddress = coordinates
        destinationString = title + " (" + address + ")"
    }
    
    func rendezvousResponse(title: String, address: String, coordinates: CLLocation) {
        rendezvousAddress = coordinates
        rendezvousString = title + " (" + address + ")"
    }
    
    //MARK: Textview delegate methods
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        textView.textColor = UIColor.blackColor()
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    //MARK: Collection View delegate methods
    
    /** Given a collection view, fades in the reload. */
    func fadeInCollectionView(collectionView: UICollectionView) {
        UIView.transitionWithView(collectionView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            collectionView.reloadData()
            }, completion: nil)
    }
    
    /** Reloads both collection views. */
    func reloadTable() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            self.setUsersRequestingAttendance()
            self.setAttendingUsers()
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == requestingUsersCollectionView {
            return usersRequesting.count
        } else {
            return attendingUsers.count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if collectionView == requestingUsersCollectionView {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RequestingUser", forIndexPath: indexPath) as! RequestingUserCell
            let imageData = goeCloudData.getProfilePhoto(usersRequesting[indexPath.row]!)
            if imageData != nil {
                cell.ProfilePicture.image = UIImage(data: imageData!)
            }
            let name = (usersRequesting[indexPath.row]?.valueForKey("Name") as? String)!
            let tempTitle = name.characters.split{$0 == "."}.map(String.init)
            cell.Name.text = tempTitle[0]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Attender", forIndexPath: indexPath) as! AttendingAdventurerCollectionViewCell
            let name = (attendingUsers[indexPath.row]?.valueForKey("Name") as? NSString)!
            let tempTitle = String(name).characters.split{$0 == "."}.map(String.init)
            cell.Name.text = tempTitle[0]
            let imageData = goeCloudData.getProfilePhoto(attendingUsers[indexPath.row]!)
            cell.ProfilePicture.image = UIImage(data: imageData!)
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if collectionView == requestingUsersCollectionView {
            accept_denyUser = usersRequesting[indexPath.row]
            performSegueWithIdentifier("requestingUserProfile", sender: self)
        } else {
            selected_user = attendingUsers[indexPath.row]
            performSegueWithIdentifier("Show Adventurer", sender: self)
        }
    }
    
    //MARK: DELETE ADVENTURE BUTTONS
    
    /** Handles the initial selection by displaying a verification alert. */
    @IBAction func deleteAdventure(sender: UIButton) {
        let doubleChecking = UIAlertController(title: "Delete Adventure?", message: "Are you sure you want to delete this adventure?", preferredStyle: UIAlertControllerStyle.Alert)
        doubleChecking.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Destructive, handler: nil))
        doubleChecking.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action in self.startDeletingAdventure() }))
        self.presentViewController(doubleChecking, animated: true, completion: nil)
    }
    
    /** Total number of responses from the server.*/
    var totalServerResponsesNeeded = 0
    
    /** Starts the deleting process by displaying the alert and then fetching the host's profile and all requesting users.*/
    func startDeletingAdventure() {
        dispatch_async(dispatch_get_main_queue()) {
            self.confirmRequest = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            self.indicator = UIActivityIndicatorView(frame: self.confirmRequest.view.bounds)
            self.indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.indicator.color = UIColor.redColor()
            self.confirmRequest.view.addSubview(self.indicator)
            self.indicator.userInteractionEnabled = false
            self.indicator.startAnimating()
            self.presentViewController(self.confirmRequest, animated: true, completion: nil)
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            let userID = (self.Adventure!["User_Host"] as? CKReference)?.recordID
            self.goeCloudData.fetchProfileWithReference((userID)!, completionHandler: self.completeHostDeletion)
            self.totalServerResponsesNeeded += 1
            let requestingUsers = self.Adventure!["User_Attending"] as? [CKReference]
            if requestingUsers?.count > 0 {
                self.totalServerResponsesNeeded += (requestingUsers?.count)!
                self.deleteAdventureFromAttendingUsers(requestingUsers!)
            }
        }
    }
    
    /** Completes the host deletion by removing it from the profile. */
    func completeHostDeletion(fetchedProfile: CKRecord?) {
        var hostingAdventures = fetchedProfile!["Adventure_Hosting"] as? [CKReference]
        for counter in 0 ..< (hostingAdventures?.count)! {
            if hostingAdventures![counter].recordID.recordName == Adventure?.recordID.recordName {
                hostingAdventures?.removeAtIndex(counter)
            }
        }
        fetchedProfile!["Adventure_Hosting"] = hostingAdventures
        goeCloudData.saveRecord(fetchedProfile!, completionHandler: completeAllDeletion)
    }
    
    /** Deletes the adventure from all attending users. */
    func deleteAdventureFromAttendingUsers(AllUsers: [CKReference]) {
        for user in AllUsers {
            goeCloudData.fetchProfileWithReference(user.recordID, completionHandler: { (profile: CKRecord?) in
                var attendingAdventures = profile!["User_Attending"] as? [CKReference]
                for counter in 0 ..< (attendingAdventures?.count)! {
                    if attendingAdventures![counter].recordID.recordName == self.Adventure?.recordID.recordName {
                        attendingAdventures?.removeAtIndex(counter)
                    }
                }
                profile!["User_Attending"] = attendingAdventures
                self.goeCloudData.saveRecord(profile!, completionHandler: self.completeAllDeletion)
            })
        }
    }
    
    /** Completes the deletion by deleting the adventure from the database.*/
    func completeAllDeletion(savedRecord: CKRecord?) {
        if savedRecord != nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.totalServerResponsesNeeded -= 1
                if self.totalServerResponsesNeeded == 0 {
                    self.goeCloudData.deleteRecord(self.Adventure!)
                    self.indicator.stopAnimating()
                    self.confirmRequest.title = "Finished deleting"
                    self.confirmRequest.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler: { action in self.performSegueWithIdentifier("refreshProfile", sender: self) }))
                }
            })
        } else {
            self.indicator.stopAnimating()
            self.confirmRequest.title = "Error"
            self.confirmRequest.message = "There was an error deleting your adventure."
            self.confirmRequest.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: { action in self.performSegueWithIdentifier("refreshProfile", sender: self) }))
        }
    }
    
    //MARK: Segue preparation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? requestingUserDetails {
            destination.requestingUser = accept_denyUser
            destination.Adventure = self.Adventure
        } else if let destination = segue.destinationViewController as? AdventureUserDetailViewController {
            destination.viewingUserDetail = selected_user
        } else if let destination = segue.destinationViewController as? ProfileViewController {
            destination.forceReload = false
        } else if let destination = segue.destinationViewController as? ChattingViewController {
            destination.Adventure_Chat = Adventure?.valueForKey("Adventure_Chat") as? CKReference
            destination.goeUtilities = self.goeUtilities
            destination.Adventure = self.Adventure
        } else if let destination = segue.destinationViewController as? MapViewController {
            destination.delegate = self
            self.goeMapDelegate = destination
        }
    }
}
