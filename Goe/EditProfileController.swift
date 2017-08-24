//
//  EditProfileController.swift
//  Goe
//
//  Created by Kadhir M on 2/28/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class EditProfileController: UIViewController, UITextViewDelegate {

    //MARK: Edit Profile Specifics
    
    /** Background scrollview.*/
    @IBOutlet weak var scrollViewBackground: UIScrollView!
    /** User's name.*/
    @IBOutlet weak var name: UITextField!
    /** User's email address.*/
    @IBOutlet weak var emailAddressField: UITextField!
    /** User's biography.*/
    @IBOutlet weak var biography: UITextView!
    /** User's background profile picture, the blurred one.*/
    @IBOutlet weak var backgroundPicture: UIImageView!
    /** User's circular profile picture.*/
    @IBOutlet weak var profilePicture: UIImageView!
    /** Indicates whether or not the users wants adventure notifications. */
    @IBOutlet weak var adventureNotifications: UISwitch!
    
    //MARK: Utility Helper Functions
    
    /** The core data helper.*/
    let goeCoreData = GoeCoreData()
    /** The cloud kit helper.*/
    let goeCloudData = GoeCloudKit()
    /** The goe utilities helper. */
    var goeUtilities = GoeUtilities()
    /** The logged in user via core data. */
    var loggedInUser: User?
    /** The logged in user's cloud kit details. */
    var loggedInUserCloudDetails: CKRecord?
    /** Confirming save alert controller. */
    var confirmingRequest: UIAlertController?
    /** Currently saving indicator. */
    var indicator: UIActivityIndicatorView?
    /** Public database. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    //MARK: Methods Begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tempLoggedInUser = goeCoreData.retrieveData("User")
        loggedInUser = tempLoggedInUser![0] as? User
        self.setPictureAttributes()
        self.ensureUserDetails()
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: self.scrollViewBackground)
        self.goeUtilities.setKeyboardObservers()
    }
    
    /** Checks to see if the cloud parameters are already set, if not, retrieves them.*/
    func ensureUserDetails(){
        if loggedInUserCloudDetails == nil {
            self.getUserDetails((self.loggedInUser?.user_ID))
        } else {
            setUserCloudParameters()
        }
    }
    
    /** Fetches the user details from the cloud and calls on setUserCloudParameters. */
    func getUserDetails(user: String?) {
        let privateDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let query = CKQuery(recordType: "User", predicate: NSPredicate(format: "ID = '\((user)!)' "))
        privateDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            if (error == nil && records?.count > 0) {
                self.loggedInUserCloudDetails = records![0]
                self.setUserCloudParameters()
            } else {
                print("Fetching user error: \(error)")
            }
        }
    }
    
    /** Sets the user's cloud settings onto the UI. */
    func setUserCloudParameters() {
        dispatch_async(dispatch_get_main_queue(), {
            if self.loggedInUserCloudDetails != nil {
                self.setSubscriptionButton()
                let emailAddress = (self.loggedInUserCloudDetails?.valueForKey("Email"))
                self.emailAddressField.text = (emailAddress as? String)!
                if let userDetails = (self.loggedInUserCloudDetails?.valueForKey("Details")) as? [String] {
                    self.biography.text = userDetails[0]
                } else {
                    self.biography.text = "None"
                }
                let tempTitle = self.loggedInUser?.user_Name?.characters.split{$0 == "."}.map(String.init)
                self.name.text = "\(tempTitle![0]) \(tempTitle![1])" ?? self.loggedInUser?.user_Name
            }
        })
    }
    
    /** Looks through the users subscriptions and sets the button to on if the user is currently subscribed to the adventures. */
    func setSubscriptionButton() {
        if loggedInUserCloudDetails?.valueForKey("Status") as? Int != 1 {
            publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions: [CKSubscription]?, error: NSError?) in
                for subscription in subscriptions! {
                    if (subscription.recordType == "Adventure" && subscription.predicate == NSPredicate(format: "TRUEPREDICATE")) {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.adventureNotifications.setOn(true, animated: true)
                        })
                    }
                }
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.adventureNotifications.setOn(true, animated: true)
            })
        }
    }
    
    /** Sets the edit profile viewcontroller specifics.*/
    func setPictureAttributes() {
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
        self.backgroundPicture.image = UIImage(data: (self.loggedInUser?.picture)!)
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = backgroundPicture.frame
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.backgroundPicture.addSubview(blurEffectView)
        
        emailAddressField.layer.borderWidth = 1.25
        emailAddressField.layer.borderColor = UIColor.blackColor().CGColor
        emailAddressField.layer.cornerRadius = 15.0
        
        biography.layer.borderWidth = 1.25
        biography.layer.borderColor = UIColor.blackColor().CGColor
        biography.layer.cornerRadius = 5.0
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.goeUtilities.setScrollViewBackgroundSize(true)
    }
    
    //MARK: IBOutlet Functionality
    
    @IBAction func nameField(sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    @IBAction func emailAddress(sender: UITextField) {
        emailAddressField.resignFirstResponder()
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    /** Save function. */
    @IBAction func Save(sender: UIButton) {
        createLoaderView()
        changeAdventureSubscription()
        loggedInUserCloudDetails!["Email"] = emailAddressField.text
        loggedInUserCloudDetails!["Details"] = [biography.text]
        let saveAsset = goeCloudData.changeImageToAsset(self.profilePicture.image!)
        loggedInUserCloudDetails!["Picture"] = saveAsset
        let tempName = self.name.text?.characters.split{$0 == " "}.map(String.init)
        var finalName = ""
        for name in tempName! {
            if finalName.characters.count > 0 {
                finalName = "\(finalName).\(name)"
            } else {
                finalName = name
            }
        }
        loggedInUserCloudDetails!["Name"] = finalName
        if adventureNotifications.on {
            let currStatus = loggedInUserCloudDetails!["Status"] as? Int
            loggedInUserCloudDetails!["Status"] = currStatus! | 1
        } else {
            let currStatus = loggedInUserCloudDetails!["Status"] as? Int
            loggedInUserCloudDetails!["Status"] = (currStatus! >> 1) << 1
        }
        loggedInUser?.user_Name = finalName
        goeCoreData.saveUser(loggedInUser!)
        goeCloudData.saveRecord(loggedInUserCloudDetails!, completionHandler: completeSave)
    }
    
    /** Displays the indicator that the view is loading. */
    func createLoaderView() {
        self.confirmingRequest = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        self.indicator = UIActivityIndicatorView(frame: self.confirmingRequest!.view.bounds)
        self.indicator!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.indicator!.color = UIColor.redColor()
        self.confirmingRequest!.view.addSubview(self.indicator!)
        self.indicator!.userInteractionEnabled = false
        self.indicator!.startAnimating()
        self.presentViewController(self.confirmingRequest!, animated: true, completion: nil)
    }
    
    /** Completes the saving process by displaying the return button. */
    func completeSave(savedRecord: CKRecord?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.indicator!.stopAnimating()
            self.confirmingRequest!.title = "Details Updated"
            self.confirmingRequest!.addAction(UIAlertAction(title: "Return", style: UIAlertActionStyle.Default, handler: { action in self.goeUtilities.segueAndForceReloadProfileViewController() }))
        }
    }
    
    /** Logout function. */
    @IBAction func Logout(sender: UIButton) {
        goeUtilities.logout(self)
    }
    
    //MARK: TextView Delegate Methods
    
    func textViewDidBeginEditing(textField: UITextView) {
        if (textField.text == "Welcome to Goe. Edit your bio with the settings button in the top right.") {
            textField.text = ""
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    //MARK: Adventure Notification Methods
    
    /** Handles the logic for when the adventuresNotification changes. */
    func changeAdventureSubscription() {
        if adventureNotifications.on {
            createAdventureSubscription()
        } else {
            deleteAdventureSubscription()
        }
    }
    
    /** Creates a subscription to all the adventures in the database. */
    func createAdventureSubscription() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKSubscription(recordType: "Adventure", predicate: predicate, options: .FiresOnRecordCreation)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = "New Adventure Posted"
        notificationInfo.soundName = UILocalNotificationDefaultSoundName
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo
        publicDatabase.saveSubscription(subscription) { (subscription, error) -> Void in
            if error != nil {
                print(error)
                //handle error case here
            } else {
                print("Changing status")
                
                self.goeCloudData.saveRecord(self.loggedInUserCloudDetails!)
            }
        }
    }
    
    /** Deletes the adventure subscription. */
    func deleteAdventureSubscription() {
        publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions: [CKSubscription]?, error: NSError?) in
            for subscription in subscriptions! {
                if (subscription.recordType == "Adventure" && subscription.predicate == NSPredicate(format: "TRUEPREDICATE")) {
                    self.publicDatabase.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {_,_ in })
                    self.loggedInUserCloudDetails!["Status"] = 2
                    self.goeCloudData.saveRecord(self.loggedInUserCloudDetails!)
                }
            }
        }
    }
    
    //MARK: Segue Preparation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? ProfileViewController {
            destination.forceReload = false
        }
    }
}
