//
//  HostNewAdventureViewController.swift
//  Goe
//
//  Created by Kadhir M on 1/16/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit
import Foundation
import EventKit
import CoreGraphics

class HostNewAdventureViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, GoeMapViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    //MARK: Goe utilities helper functions
    
    /** Goe utilities helper with cloud kit.*/
    let goeCloudKitHelper = GoeCloudKit()
    /** Goe utilities helper with core data.*/
    let goeCoreDataHelper = GoeCoreData()
    /** Core location utilities helper.*/
    let goeCoreLocationHelper = GoeCoreLocationHelper()
    /** Utilties helper function. */
    var goeUtilities = GoeUtilities()
    /** addressChecker regex functionality.*/
    let addressChecker = Regex()
    
    //MARK: IBOutlets for host items
    
    /** The adventure's name. */
    @IBOutlet weak var adventureName: UITextField!
    /** The total number of spots in the adventure. */
    @IBOutlet weak var numSpots: UILabel!
    /** The autosteppher to increase the number of spots. */
    @IBOutlet weak var autoStepper: UIStepper!
    /** The background view this whole controller is in. */
    @IBOutlet var backgroundView: UIView!
    /** The background scrollview. */
    @IBOutlet weak var backgroundScrollView: UIScrollView!
    /** The adventure image collection view. */
    @IBOutlet weak var imagePicker: UICollectionView!
    /** The adventure description. */
    @IBOutlet weak var adventureDescription: UITextView!
    /** The error text displayed above host. */
    @IBOutlet weak var errorText: UILabel!
    /** The date picker tableview. */
    @IBOutlet weak var DatePickerTableView: UITableView!
    /** The estimated cost. */
    @IBOutlet weak var estimatedCost: UITextField!
    /** The equipment needed for the adventure. */
    @IBOutlet weak var equipment: UITextView!
    /** Category uipicker view. */
    @IBOutlet weak var categoryPicker: UIPickerView!
    
    //MARK: Host variables
    
    /** Date setter and helper for the the tableview. */
    var dates = ["start_date": NSDate(), "end_date": NSDate()]
    /** Available photos for adventure images. */
    var photos: [UIImage?]?
    /** Categories in which the adventures can fall into. */
    let categories = ["Camping/Hiking", "Surfing/Beach", "Skiing/Snowboarding", "Other"]
    /** Selected category. */
    var selectedCategory: String?
    /** Photos associated with categories. */
    let photoDictionary: [String: [UIImage?]] = [
        "Camping/Hiking" : [
            UIImage(named: "costa_rica_hills"),
            UIImage(named: "path_waterfront"),
            UIImage(named: "rolling_hills"),
            UIImage(named: "rocky"),
            UIImage(named: "golden_gate_tina"),
            UIImage(named: "clouds_golden_gate")
        ],
        "Surfing/Beach": [
            UIImage(named: "bay_bridge_water"),
            UIImage(named: "beach_sunset"),
            UIImage(named: "water_rocks"),
            UIImage(named: "water_formation"),
            UIImage(named: "city_scape")
        ],
        "Skiing/Snowboarding": [
            UIImage(named: "curry_village")
        ],
        "Other": [
            UIImage(named: "golden_gate"),
            UIImage(named: "central_park"),
            UIImage(named: "dock"),
            UIImage(named: "times_square"),
            UIImage(named: "bay_bridge")
        ]
    ]
    /** The final selected adventure image. */
    var adventureImage: UIImage?
    /** The selected adventure image indexPath. */
    var adventureImageIndexPath: NSIndexPath?
    /** Total spots helper integer. */
    var totalSpots: Int?
    /** Sets the UI for the total available spots. */
    var totalSpotsSetter: Int? {
        get {
            return totalSpots
        }
        set {
            totalSpots = newValue
            numSpots.text = "Spots: \(newValue!)"
        }
    }
    /** The current logged in user from core data. */
    var loggedInUser: User?
    /** The current logged in user's cloudkit data. */
    var loggedInUserCloud: CKRecord?
    /** The public database accesser. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    /** The selected date in the uitableview. */
    var selectedDatePath: NSIndexPath?
    /** The final destination location. */
    var destinationAddress: CLLocation?
    var destinationString: String?
    /** The final origin location .*/
    var rendezvousAddress: CLLocation?
    var rendezvousString: String?
    /** Confirming adventure creation activity indicator. */
    var globalIndicator = UIActivityIndicatorView()
    /** Confirming adventure alert view controller. */
    var confirmingRequest = UIAlertController()
    /** The total number of server responses the form should get.*/
    var totalServerResponses = 2
    /** Sets the text for the GoeMapView. */
    var goeMapDelegate: GoeMapContainerDelegate?
    
    //MARK: Loading Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setStartingPictures()
        self.setItemDefaults()
        self.fetchUser()
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: self.backgroundScrollView)
        self.goeUtilities.setKeyboardObservers()
    }
    
    /** Sets the initial pictures. */
    func setStartingPictures() {
        self.photos = self.photoDictionary[self.categories[0]]
        self.selectedCategory = self.categories[0]
        self.imagePicker.reloadData()
    }
    
    /** Sets host item defaults. */
    func setItemDefaults() {
        autoStepper.autorepeat = true
        autoStepper.wraps = true
        adventureDescription.delegate = self
        self.DatePickerTableView.sizeToFit()
        let tempLoggedInUser = goeCoreDataHelper.retrieveData("User")
        loggedInUser = tempLoggedInUser![0] as? User
        self.imagePicker.delegate = self
        self.imagePicker.dataSource = self
    }
    
    /** Fetches the user's profile. */
    func fetchUser() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "ID = '\((self.loggedInUser!.user_ID)!)' "))
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                self.loggedInUserCloud = records![0]
                self.goeUtilities.checkUserBio(self.loggedInUserCloud!)
            }
        }
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setBackgroundSize()
        setRandomImage()
        goeMapDelegate!.mapDestination("Address of Destination", coordinates: nil, textEntryEnabled: true)
        goeMapDelegate!.mapRendezvous("Address of Rendezvous", coordinates: nil, textEntryEnabled: true)
    }
    
    /** Sets the randomized starting image. */
    func setRandomImage() {
        let random_image = Int(arc4random_uniform(UInt32(photos!.count)))
        let indexPath = NSIndexPath(forItem: Int(random_image), inSection: 0)
        adventureImageIndexPath = indexPath
        adventureImage = photos![random_image]
        UIView.transitionWithView(imagePicker, duration: 0.75, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.imagePicker.reloadData()
        }) { (completed) in
            if completed {
                self.imagePicker.scrollToItemAtIndexPath(self.adventureImageIndexPath!, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
            }
        }
    }
    
    /** Sets the background size to the size of all content inside. */
    func setBackgroundSize(scrollToDatePicker: Bool = false){
        dispatch_async(dispatch_get_main_queue()) {
            var contentRect = CGRectZero
            for view in self.backgroundScrollView.subviews {
                contentRect = CGRectUnion(contentRect, view.frame)
            }
            self.backgroundScrollView.contentSize = CGSize(width: self.view.frame.width, height: contentRect.height)
            if scrollToDatePicker {
                let bottom = CGRect(x: 0, y: (self.DatePickerTableView.frame.midY + 75), width: 1, height: 1)
                self.backgroundScrollView.scrollRectToVisible(bottom, animated: true)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        for cell in DatePickerTableView.visibleCells as! [DatePickerTableViewCell] {
            cell.ignoreFrameChanges()
        }
    }
    
    //MARK: IBOutlet Handlers
    
    /** Handler to change the number of spots the adventure has.*/
    @IBAction func changeNumberOfSpots(sender: UIStepper) {
        totalSpotsSetter = Int(sender.value)
    }
    
    /** Handler for when the adventure title first starts editing. */
    @IBAction func deleteAdventureTitle(sender: UITextField) {
        if sender.text == "Adventure Title" {
            sender.text = ""
        }
    }
    
    /** Handles the title's primary button. */
    @IBAction func AdventureTitle(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    /** Cost did start editing. */
    @IBAction func costDidStart(sender: UITextField) {
        if sender.text == "Eg. $10 - $15" {
            sender.text = ""
        }
    }
    
    /** Cost done button handler. */
    @IBAction func resignCost(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    /** Host adventure handler.*/
    @IBAction func hostAdventure(sender: AnyObject) {
        let checks = [checkOrigin(), checkDestination(), checkDate(), checkOpenSpots(), checkDescription(), checkTitle(), checkImage(), checkStatus()]
        if !checks.contains(false) {
            errorText.text = ""
            createAlertController()
        }
    }
    
    //MARK: Textview Delegate Items
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        textView.showsVerticalScrollIndicator = true
        textView.scrollEnabled = true
        textView.textColor = UIColor.blackColor()
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.showsVerticalScrollIndicator = false
        textView.scrollEnabled = false
        switch textView {
        case adventureDescription:
            if textView.text == "Adventure Description" {
                textView.text = ""
            }
        case equipment:
            if textView.text == "What should everyone bring?" {
                textView.text = ""
            }
        default:
            break
        }
    }
    
    //MARK: Checker functions
    
    func checkImage() -> Bool {
        if adventureImage == nil {
            errorText.text = "Must select an image for your adventure."
            return false
        } else {
            return true
        }
    }
    
    func checkTitle() -> Bool {
        if adventureName.text == "Adventure Title" {
            errorText.text = "Don't forget to set your adventure title."
            return false
        } else if adventureName.text == "" {
            errorText.text = "Must have an adventure title."
            return false
        } else {
            return true
        }
    }
    
    func checkDescription() -> Bool {
        if adventureDescription.text == "Adventure Description" {
            errorText.text = "Don't forget to set your adventure description."
            return false
        } else if adventureDescription.text == "" {
            errorText.text = "Must have an adventure description."
            return false
        } else {
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
    
    func checkOpenSpots() -> Bool {
        if totalSpots > 0 {
            return true
        } else {
            errorText.text = "You must have at least one spot in your adventure."
            return false
        }
    }
    
    func checkDate() -> Bool {
        let date = NSDate()
        let start = dates["start_date"]!
        let diff = dates["end_date"]!.offsetFrom(start)
        let true_delta = diff.day*24*60 + diff.hour*60+diff.minute
        if start.compare(date).rawValue == 1 {
            if true_delta >= 45 {
                return true
            } else {
                errorText.text = "Adventures must be at least 45 minutes long."
                return false
            }
        } else {
            errorText.text = "Adventure dates can't be in the past."
            return false
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
    
    func checkStatus() -> Bool {
        if (loggedInUserCloud!["Status"] as? Int) == 666 {
            errorText.text = "You have been blocked from Goe. Contact support@goeadventure.com if you think this is a mistake."
            return false
        }
        return true
    }
    
    //MARK: Adventure Creation Methods
    
    /** Confirms that the user wants to create the adventure.*/
    func createAlertController() {
        confirmingRequest = UIAlertController(title: "Confirm Adventure", message: "Create \(adventureName.text!)?", preferredStyle: UIAlertControllerStyle.Alert)
        confirmingRequest.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (action) in
            self.startCreatingAdventure()
        }))
        confirmingRequest.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Destructive, handler: nil))
        self.presentViewController(confirmingRequest, animated: true, completion: nil)
    }
    
    /** Loads the activity indicator and fetches the user's profile.*/
    func startCreatingAdventure() {
        fetchProfile()
        dispatch_async(dispatch_get_main_queue()) {
            self.confirmingRequest = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            self.globalIndicator = UIActivityIndicatorView(frame: self.confirmingRequest.view.bounds)
            self.globalIndicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.globalIndicator.color = UIColor.blackColor()
            self.confirmingRequest.view.addSubview(self.globalIndicator)
            self.globalIndicator.userInteractionEnabled = false
            self.globalIndicator.startAnimating()
            self.presentViewController(self.confirmingRequest, animated: true, completion: nil)
        }
    }
    
    /** Fetches the users profile. */
    func fetchProfile() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            let query = CKQuery(recordType: "Profile", predicate: NSPredicate(format: "User_ID = '\((self.loggedInUser!.user_ID)!)' "))
            self.publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if error == nil {
                    self.createNewAdventureWithParameters(records![0])
                } else {
                    print("Profile fetching error: \(error)")
                }
            }
        }
    }
    
    /** Creates a CKRecord with all the adventure details present in the form. */
    func createNewAdventureWithParameters(profile: CKRecord) {
        let newAdventure = CKRecord(recordType: "Adventure")
        newAdventure["Name"] = adventureName.text!.lowercaseString
        newAdventure["Description"] = adventureDescription.text!
        let start_date = (dates["start_date"]!)
        let end_date = (dates["end_date"]!)
        newAdventure["Start_Date"] = start_date
        newAdventure["End_Date"] = end_date
        newAdventure["Spots"] = totalSpots
        newAdventure["User_Host"] = CKReference(record: loggedInUserCloud!, action: CKReferenceAction.DeleteSelf)
        let imageAsset = goeCloudKitHelper.changeImageToAsset(adventureImage!)
        newAdventure["Photo"] = imageAsset
        newAdventure["ID"] = adventureName.hashValue
        newAdventure["Destination"] = destinationAddress
        newAdventure["String_Destination"] = destinationString
        newAdventure["Origin"] = rendezvousAddress
        newAdventure["String_Origin"] = rendezvousString
        if (estimatedCost.text?.characters.count == 0 || estimatedCost.text == "Eg. $10 - $15" ) {
            newAdventure["Estimated_Cost"] = "Unspecified"
        } else {
            newAdventure["Estimated_Cost"] = estimatedCost.text ?? "Free"
        }
        if (equipment.text?.characters.count == 0 || equipment.text == "What should everyone bring?" ) {
            newAdventure["Equipment"] = "Unspecified"
        } else {
            newAdventure["Equipment"] = equipment.text ?? "None"
        }
        newAdventure["Category"] = selectedCategory!
        
        let newAdventureChat = CKRecord(recordType: "Adventure_Chat")
        newAdventureChat["Chats"] = [String]()
        newAdventureChat["Name"] = adventureName.text!
        newAdventureChat["ID"] = adventureName.hashValue
        newAdventureChat["Adventure"] = CKReference(record: newAdventure, action: CKReferenceAction.DeleteSelf)
        goeCloudKitHelper.saveRecord(newAdventureChat) { (savedRecord) in
            if savedRecord != nil {
                newAdventure["Adventure_Chat"] = CKReference(record: newAdventureChat, action: CKReferenceAction.None)
                self.createAdventure(profile, newAdventure: newAdventure)
            } else {
                print("Saving chat error: \(newAdventureChat)")
            }
        }
    }
    
    /** Creates the adventure using the given parameters in the form.*/
    func createAdventure(profile: CKRecord, newAdventure: CKRecord) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            let adventureID = newAdventure["ID"] as! Int
            self.goeCloudKitHelper.saveRecord(newAdventure, completionHandler: self.successfullyCreated)
            self.createAdventureSubscription(adventureID)
            self.addToCalendar(newAdventure)
            self.addAdventureToUserHostingList(profile, newAdventure: newAdventure)
        }
    }
    
    /** Creates a CKSubscription for the host user on this specific adventure.*/
    func createAdventureSubscription(adventureID: Int) {
        let predicate = NSPredicate(format: "ID = \(adventureID)")
        let subscription = CKSubscription(recordType: "Adventure", predicate: predicate, options: .FiresOnRecordUpdate)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = adventureName.text! + ": New Requesting User"
        notificationInfo.soundName = UILocalNotificationDefaultSoundName
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo
        let publicContainer = CKContainer.defaultContainer()
        let publicDatabase = publicContainer.publicCloudDatabase
        publicDatabase.saveSubscription(subscription) { (subscription, error) -> Void in
            if error != nil {
                print(error)
                //handle error case here
            }
        }
    }
    
    /** Adds this event to the users calendar. */
    func addToCalendar(newAdventure: CKRecord) {
        let calendar = EKEventStore.init()
        let newItem = EKEvent(eventStore: calendar)
        newItem.title = "goe Adventure: " + (newAdventure.valueForKey("Name") as! String)
        newItem.startDate = newAdventure.valueForKey("Start_Date") as! NSDate
        newItem.endDate = newAdventure.valueForKey("End_Date") as! NSDate
        newItem.location = (newAdventure.valueForKey("String_Destination") as! String)
        let startDate = newAdventure.valueForKey("Start_Date") as! NSDate
        let firstAlarm = startDate.dateByAddingTimeInterval(-60*60*Time_Constants.Host.HOURS_BEFORE_FIRST_REMINDER)
        let secondAlarm = startDate.dateByAddingTimeInterval(-60*60*Time_Constants.Host.HOURS_BEFORE_SECOND_REMINDER)
        newItem.alarms = [EKAlarm(absoluteDate: firstAlarm), EKAlarm(absoluteDate: secondAlarm)]
        newItem.notes = "You are hosting this adventure."
        newItem.calendar = calendar.defaultCalendarForNewEvents
        do{
            try calendar.saveEvent(newItem, span: EKSpan.ThisEvent)
        }
        catch _ {
            print("Error Occurred Saving Calendar!")
            //handle error case here
        }
    }
    
    /** Adds the current adventure to the user's profile. */
    func addAdventureToUserHostingList(profile: CKRecord?, newAdventure: CKRecord) {
        var currentProfileHosting = profile!["Adventure_Hosting"] as? [CKReference] ?? []
        let newAdventureToAddToHosting = CKReference(record: newAdventure, action: CKReferenceAction.None)
        currentProfileHosting.append(newAdventureToAddToHosting)
        profile!["Adventure_Hosting"] = currentProfileHosting
        goeCloudKitHelper.saveRecord(profile!, completionHandler: successfullyCreated)
    }
    
    /** Once the server responds a totalServerResponse times, will change the alert controller and pop the current viewcontroller. */
    func successfullyCreated(newAdventure: CKRecord?) {
        dispatch_async(dispatch_get_main_queue()) {
            if newAdventure != nil {
                self.totalServerResponses -= 1
                if self.totalServerResponses == 0 {
                    self.confirmingRequest = UIAlertController(title: "Successfully Created", message: "Your adventure has now been posted.", preferredStyle: UIAlertControllerStyle.Alert)
                    let returnToAdventure = UIAlertAction(title: "Return", style: UIAlertActionStyle.Default) { (action) in
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                    self.confirmingRequest.addAction(returnToAdventure)
                    self.dismissViewControllerAnimated(false, completion: nil)
                    self.presentViewController(self.confirmingRequest, animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: View Did Disappear
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: Collection View Methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photos != nil {
            return photos!.count
        } else {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("picture", forIndexPath: indexPath) as! ImagePickerCell
        cell.image.image = photos![indexPath.item]
        if cell.image.image == adventureImage {
            cell.tint.backgroundColor = UIColor.clearColor()
            imagePicker.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: true)
        } else {
            cell.tint.backgroundColor = UIColor.grayColor()
        }
        cell.layer.borderColor = UIColor.blackColor().CGColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImagePickerCell
        cell.tint.backgroundColor = UIColor.clearColor()
        adventureImage = photos![indexPath.row]!
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ImagePickerCell {
            cell.tint.backgroundColor = UIColor.grayColor()
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        if photos!.count == 1 {
            let imageWidth = collectionView.frame.width * 0.718
            let inset = (self.view.frame.width - imageWidth)/2
            return UIEdgeInsetsMake(0, inset, 0, inset)
        }
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    //MARK: UITableView Delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let date_cell = self.DatePickerTableView.dequeueReusableCellWithIdentifier("DatePicker") as! DatePickerTableViewCell
        if indexPath.row == 0 {
            date_cell.label.text = "Start:"
            date_cell.DatePicker.date = dates["start_date"]!
            let comparer = dates["end_date"]!.compare(dates["start_date"]!)
            if  comparer.rawValue < 0{
                dates["end_date"] = dates["start_date"]
            }
        } else {
            date_cell.label.text = "End:"
            date_cell.DatePicker.date = dates["end_date"]!
        }
        date_cell.setCellDate(date_cell.DatePicker.date)
        return date_cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == selectedDatePath {
            return DatePickerTableViewCell.expandedHeight
        } else {
            return DatePickerTableViewCell.defaultHeight
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let previousIndexPath = selectedDatePath
        if indexPath == selectedDatePath {
            selectedDatePath = nil
        } else {
            selectedDatePath = indexPath
        }
        
        var indexPaths : Array<NSIndexPath> = []
        if let previous = previousIndexPath {
            indexPaths += [previous]
        }
        if let current = selectedDatePath {
            indexPaths += [current]
        }
        if indexPaths.count > 0 {
            for path in indexPaths {
                update_date(path)
            }
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Automatic)
            changeSizes()
        }
    }
    
    /** Updates the date on the DatePickerTableView. */
    func update_date(indexPath: NSIndexPath){
        let cell = self.DatePickerTableView.cellForRowAtIndexPath(indexPath) as! DatePickerTableViewCell
        if indexPath.row == 0 {
            dates["start_date"] = cell.DatePicker.date
        } else {
            dates["end_date"] = cell.DatePicker.date
        }
    }
    
    /** Changes the size of the Date Picker Table View, then activates the constraints and calls setBackgroundSize. */
    func changeSizes() {
        NSLayoutConstraint.deactivateConstraints(self.DatePickerTableView.constraints)
        self.DatePickerTableView.reloadData()
        self.DatePickerTableView.sizeToFit()
        let height = self.DatePickerTableView.contentSize.height
        let newConstraint = NSLayoutConstraint(item: self.DatePickerTableView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: height)
        NSLayoutConstraint.activateConstraints([newConstraint])
        self.setBackgroundSize(true)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        (cell as! DatePickerTableViewCell).watchFrameChanges()
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let date_cell = cell as! DatePickerTableViewCell
        date_cell.ignoreFrameChanges()
    }
    
    //MARK: GoeAdventureLocation Delegate
    
    func destinationResponse(title: String, address: String, coordinates: CLLocation) {
        self.destinationAddress = coordinates
        destinationString = title + "(" + address + ")"
    }
    
    func rendezvousResponse(title: String, address: String, coordinates: CLLocation) {
        self.rendezvousAddress = coordinates
        rendezvousString = title + "(" + address + ")"
    }
    
    func goeMapTextViewDidBeginEditing(textView: UITextView) {
        dispatch_async(dispatch_get_main_queue()) {
            let adjustment = self.backgroundScrollView.contentInset.bottom * 1.5
            let content = UIEdgeInsets(top: 0, left: 0, bottom: adjustment, right: 0)
            self.backgroundScrollView.contentInset = content
            self.backgroundScrollView.scrollIndicatorInsets = content
        }
    }
    
    func goeMapTextViewDidEndEditing(textView: UITextView) {
        dispatch_async(dispatch_get_main_queue()) {
            let adjustment = self.backgroundScrollView.contentInset.bottom * 1.5
            let content = UIEdgeInsets(top: 0, left: 0, bottom: -adjustment, right: 0)
            self.backgroundScrollView.contentInset = content
            self.backgroundScrollView.scrollIndicatorInsets = content
        }
    }
    
    //MARK: UIPickerView Delegate
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let titleLabel = UILabel()
        let titleData = NSAttributedString(string: categories[row], attributes: [NSFontAttributeName:UIFont(name: "MankSans-Medium", size: 25)!])
        titleLabel.attributedText = titleData
        titleLabel.textAlignment = .Center
        return titleLabel
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return CGFloat(30)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        photos = photoDictionary[(categories[row])]!
        selectedCategory = categories[row]
        setRandomImage()
    }
    
    //MARK: Prepare For Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? MapViewController {
            destination.delegate = self
            self.goeMapDelegate = destination
        }
    }
}

extension NSDate {
    
    /** Returns the different of one NSDate from another. */
    func offsetFrom(date:NSDate) -> NSDateComponents {
        let dayHourMinuteSecond: NSCalendarUnit = [.Day, .Hour, .Minute, .Second]
        let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: date, toDate: self, options: [])
        return difference
    }
    
}

class Regex {
    /** Internal expression. */
    private let internalExpression: NSRegularExpression?
    /** The pattern to look for.*/
    private let pattern: String
    
    init() {
        self.pattern = "\\d{1,3}.?\\d{0,3}\\s[a-zA-Z]{2,30}\\s[a-zA-Z]{2,15}" // Address Regex
        do {
            self.internalExpression = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
        } catch let error as NSError {
            self.internalExpression = nil
            print(error)
        }
    }
    
    /** Returns true if the input matches the pattern.*/
    func test(input: String) -> Bool {
        if internalExpression != nil {
            let matches = self.internalExpression!.matchesInString(input, options: NSMatchingOptions.ReportProgress, range:NSMakeRange(0, input.characters.count))
            return matches.count > 0
        }
        return false
    }
}
