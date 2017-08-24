//
//  RateAdventure.swift
//  Goe
//
//  Created by Kadhir M on 4/9/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class RateAdventureViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RatingUsersCellScroll {

    //MARK: Utility Helper Functions
    
    /** Goe core data helper.*/
    let goeCoreData = GoeCoreData()
    /** Goe cloud data helper.*/
    let goeCloudData = GoeCloudKit()
    /** The public database for Goe.*/
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    /** The goe utilities helper. */
    var goeUtilities = GoeUtilities()
    
    //MARK: Adventure Specific Functions
    
    /** All the CKRecords of adventures to rate.*/
    var AdventureToRate: CKRecord?
    /** The current user logged in.*/
    var currentUser: CKRecord?
    /** The current user's profile.*/
    var currentUserProfile: CKRecord?
    
    //MARK: Adventure Nonspecific Items
    
    /** The new adventure history record.*/
    var AdventureHistory: CKRecord?
    /** Confirming request alert controller.*/
    var confirmingRequest = UIAlertController()
    /** The indicator that the rating is being submitted.*/
    var indicator = UIActivityIndicatorView()
    /** The current logged in user. */
    var loggedInUser: User?
    /** Fetched user details. */
    var allUsers = [CKRecord]()
    /** Number of server responses to expect. */
    var totalUsersAttended: Int?
    /** Total number of items to process. */
    var totalCompletedProcesses = 2
    
    //MARK: IBOutlet Items
    
    /** The adventure's date. */
    @IBOutlet weak var adventure_date: UILabel!
    /** The adventure's title. */
    @IBOutlet weak var adventure_title: UILabel!
    /** The adventure's image. */
    @IBOutlet weak var adventureImage: UIImageView!
    /** The overall rating. */
    @IBOutlet weak var overallRating: UISlider!
    /** The people rating. */
    @IBOutlet weak var peopleRating: UISlider!
    /** All users to be rated. */
    @IBOutlet weak var allUsersTableView: UITableView!
    /** Indicates the user table view is loading. */
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    /** Background scroll view. */
    @IBOutlet weak var backgroundScrollView: UIScrollView!
    /** Company logo. */
    @IBOutlet weak var companyLogo: UIImageView!
    
    //MARK: Methods Begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setParameters()
        let tempLoggedInUser = goeCoreData.retrieveData("User")
        loggedInUser = tempLoggedInUser![0] as? User
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: backgroundScrollView)
        self.startFetchingAllUsers()
        self.goeUtilities.setKeyboardObservers()
    }
    
    /** Sets the UI parameters for the adventure. */
    func setParameters() {
        let imageData = goeCloudData.getAdventurePhoto(AdventureToRate!)
        if imageData != nil {
            adventureImage.image = UIImage(data: imageData!)
        }
        adventure_title.text = AdventureToRate!["Name"] as? String
        let startDate = NSDateFormatter.localizedStringFromDate((AdventureToRate!.valueForKey("Start_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        let endDate = NSDateFormatter.localizedStringFromDate((AdventureToRate!.valueForKey("End_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        adventure_date.text = "\(startDate) - \(endDate)"
        let logo = self.AdventureToRate?.valueForKey("Logo") as? CKAsset
        if logo != nil {
            let logo = self.goeCloudData.changeAssetToImage(logo!)
            if logo != nil {
                self.companyLogo?.image = logo!
            }
        }
    }
    
    /** Goes through and creates the list of CKReferences of users to rate, excluding the current user. */
    func startFetchingAllUsers() {
        let host = AdventureToRate?.valueForKey("User_Host") as! CKReference
        var attendees_list = AdventureToRate?.valueForKey("User_Attending") as? [CKReference] ?? []
        if (attendees_list.count > 0 && attendees_list.count <= 10) {
            attendees_list.append(host)
            for index in 0...(attendees_list.count - 1) {
                if attendees_list[index].recordID.recordName == self.loggedInUser?.user_reference {
                    attendees_list.removeAtIndex(index)
                    break
                }
            }
            totalUsersAttended = attendees_list.count
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
                for user in attendees_list {
                    self.goeCloudData.fetchReference(user, completionHandler: self.appendToMainAdventure)
                }
            }
        } else {
            activityIndicator.stopAnimating()
            allUsersTableView.hidden = true
            totalUsersAttended = 0
        }
    }
    
    /** Handles the completion of server response and appends all users to the main array. */
    func appendToMainAdventure(fetchedUser: CKRecord?) {
        dispatch_async(dispatch_get_main_queue()) {
            if fetchedUser != nil {
                self.allUsers.append(fetchedUser!)
                if self.allUsers.count == self.totalUsersAttended {
                    UIView.transitionWithView(self.allUsersTableView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                        self.allUsersTableView.reloadData()
                        }, completion: { action in
                            self.activityIndicator.stopAnimating()
                            self.adjustTableViewHeight()
                    })
                }
            } else {
                self.totalUsersAttended! -= 1
            }
        }
    }
    
    /** Adjusts the height of the table view. */
    func adjustTableViewHeight() {
        NSLayoutConstraint.deactivateConstraints(self.allUsersTableView.constraints)
        self.allUsersTableView.sizeToFit()
        let height = self.allUsersTableView.contentSize.height
        let newConstraint = NSLayoutConstraint(item: self.allUsersTableView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: height)
        NSLayoutConstraint.activateConstraints([newConstraint])
        self.goeUtilities.setScrollViewBackgroundSize(true)
    }
    
    /** Begins the rating submission process. */
    @IBAction func submit(sender: UIButton) {
        if activityIndicator.isAnimating() == false {
            let completedRequest = UIAlertController(title: "Submit Rating?", message: "Note that comments are optional and not anonymous.", preferredStyle: UIAlertControllerStyle.Alert)
            completedRequest.addAction(UIAlertAction(title: "Submit", style: UIAlertActionStyle.Default, handler: { action in self.createAdventureHistory() } ))
            completedRequest.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: nil ))
            self.presentViewController(completedRequest, animated: true, completion: nil)
        }
    }
    
    /** Creates the alert view controller and initializes the adventure history creation. */
    func createAdventureHistory() {
        if totalUsersAttended > 0 {
            startSubmittingUserReviews()
        } else {
            totalCompletedProcesses -= 1
        }
        startSubmission()
        dispatch_async(dispatch_get_main_queue()) {
            self.confirmingRequest = UIAlertController(title: "", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            self.indicator = UIActivityIndicatorView(frame: self.confirmingRequest.view.bounds)
            self.indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            self.indicator.color = UIColor.redColor()
            self.confirmingRequest.view.addSubview(self.indicator)
            self.indicator.userInteractionEnabled = false
            self.indicator.startAnimating()
            self.presentViewController(self.confirmingRequest, animated: true, completion: nil)
        }
    }
    
    /** Starts submitting the reviews for each user. */
    func startSubmittingUserReviews() {
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Day , .Month , .Year], fromDate: date)
        let finalDate =  "\(components.month)/\(components.day)/\(components.year)"
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            for row in 0...(self.allUsers.count - 1) {
                let indexPath = NSIndexPath(forRow: row, inSection: 0)
                let cell = self.allUsersTableView.cellForRowAtIndexPath(indexPath) as? RatingUsersTableViewCell
                self.goeCloudData.refreshCKRecord((cell?.user)!, completionHandler: { (user) in
                    if (cell?.userReview.text.characters.count > 0 && cell?.userReview.text != "Say something about \((cell?.username.text)!)") {
                        var details = user?.valueForKey("Details") as? [String]
                        let review = "\((self.loggedInUser?.user_ID)!)||\((self.loggedInUser?.user_Name)!)||\(finalDate)||\((cell?.userReview.text)!)"
                        details?.append(review)
                        user!["Details"] = details
                    }
                    var goeRating = user?.valueForKey("Goe_Rating") as! Int
                    if cell?.attendedIndicator == true {
                        goeRating += 2
                    } else {
                        goeRating -= 2
                    }
                    if cell?.wasPreparedIndicator == true {
                        goeRating += 2
                    } else {
                        goeRating -= 2
                    }
                    user!["Goe_Rating"] = goeRating
                    self.goeCloudData.saveRecord(user!, completionHandler: self.completeUserReviewSubmissions)
                })
            }
        }
    }
    
    /** Completes the user review submission once all the records are in. */
    func completeUserReviewSubmissions(savedRecord: CKRecord?) {
        dispatch_async(dispatch_get_main_queue()) {
            self.totalUsersAttended! -= 1
            if self.totalUsersAttended! == 0 {
                self.completeAllRatingSubmissions(savedRecord)
            }
        }
    }
    
    /** Begins the rating submission process by finding the adventure history. */
    func startSubmission() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let id = self.AdventureToRate?.valueForKey("ID") as? NSNumber
            let predicate = NSPredicate(format: "ID = \(id!)")
            let query = CKQuery(recordType: "Adventure_History", predicate: predicate)
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                self.AdventureHistory = nil
                if records?.count > 0{
                    self.AdventureHistory = records![0]
                }
                self.completeSubmission()
            }
        }
    }
    
    /** Completes the submission by creating appending the ratings and submitting. */
    func completeSubmission() {
        if AdventureHistory != nil {
            var totalRatings = (AdventureHistory!["Ratings"] as? [Double])!
            let overall = Double(round(overallRating.value*10)/10)
            let people = Double(round(peopleRating.value*10)/10)
            totalRatings[0] = (totalRatings[0]+overall)
            totalRatings[1] = (totalRatings[1]+people)
            totalRatings[2] -= 1
            AdventureHistory!["Ratings"] = totalRatings
            logicControllerCompletion(totalRatings)
        } else {
            logicControllerCompletion(nil)
        }
    }
    
    /** Figures out and completes the logic for the submission. */
    func logicControllerCompletion(totalRatings: [Double]?) {
        let totalNum = (AdventureToRate!["User_Attending"] as? [CKReference])?.count
        if totalNum > 0 {
            goeCloudData.saveRecord(AdventureHistory!)
            increaseGoeRating()
            if Int(totalRatings![2]) == 0{
                goeCloudData.deleteRecord(AdventureToRate!)
            }
        } else {
            goeCloudData.deleteRecord(AdventureToRate!)
        }
        deleteNotification()
        adjustProfile()
    }
    
    /** Increases the users Goe rating. */
    func increaseGoeRating() {
        let currentRating = currentUser!["Goe_Rating"] as? Int ?? 0
        currentUser!["Goe_Rating"] = currentRating + 5
        goeCloudData.saveRecord(currentUser!)
    }
    
    /** Deletes the host user's notification. */
    func deleteNotification() {
        let adventureID = AdventureToRate!["ID"] as? Int
        let predicate = NSPredicate(format: "ID = \(adventureID!)")
        publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions: [CKSubscription]?, error: NSError?) in
            for subscription in subscriptions! {
                if (subscription.predicate?.isEqual(predicate))! == true {
                    self.publicDatabase.deleteSubscriptionWithID(subscription.subscriptionID, completionHandler: {_,_ in
                    })
                }
            }
        }
    }
    
    /** Adjusts the user's profile to include this adventure in their history. */
    func adjustProfile() {
        var recentlyCompleted = currentUserProfile!["Adventure_Completed"] as? [CKReference]
        var index = 0
        for adventureCompleted in recentlyCompleted! {
            if adventureCompleted.recordID == AdventureToRate?.recordID {
                recentlyCompleted?.removeAtIndex(index)
            }
            index += 1
        }
        currentUserProfile!["Adventure_Completed"] = recentlyCompleted
        let totalNum = (AdventureToRate!["User_Attending"] as? [CKReference])?.count
        if totalNum > 0 {
            var history = currentUserProfile!["Adventure_History"] as? [CKReference] ?? []
            history.append(CKReference(record: AdventureHistory!, action: CKReferenceAction.None))
            currentUserProfile!["Adventure_History"] = history
        }
        goeCloudData.saveRecord(currentUserProfile!, completionHandler: completeAllRatingSubmissions)
    }
    
    /** Completes all the rating submissions then segues back to the profile view controller. */
    func completeAllRatingSubmissions(record: CKRecord?) {
        if record != nil {
            dispatch_async(dispatch_get_main_queue()) {
                self.totalCompletedProcesses -= 1
                if self.totalCompletedProcesses == 0 {
                    self.indicator.stopAnimating()
                    self.confirmingRequest.title = "Finished Submitting Rating"
                    self.confirmingRequest.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler: { action in self.goeUtilities.segueAndForceReloadProfileViewController() }))
                }
                
            }
        } else {
            print("Error completing rating submission.")
            //Error needs to be handled
        }
    }
    
    //MARK: Table View Delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allUsers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("User") as? RatingUsersTableViewCell
        let user = allUsers[indexPath.row]
        let tempData = self.goeCloudData.getProfilePhoto(user)
        if tempData != nil {
            print("Reaching to set image")
            cell?.profileImage.image = UIImage(data: tempData!)
        }
        let firstName = goeUtilities.splitUserName(user.valueForKey("Name") as! String, returnname: "First")
        cell?.username.text = firstName
        cell?.userReview.text = "Say something about \(firstName)"
        cell?.user = user
        cell?.indexPath = indexPath
        cell?.delegate = self
        return cell!
    }
    
    /** Moves the scroll view to show the index path. */
    func selectedIndexPath(path: NSIndexPath) {
        let additionalHeight = CGFloat(path.row * 25)
        let y = (allUsersTableView.frame.minY + additionalHeight)
        let finalRect = CGRect(x: 0, y: y, width: CGFloat(1), height: CGFloat(1))
        self.goeUtilities.scrollToShowRect(finalRect)
    }
}
