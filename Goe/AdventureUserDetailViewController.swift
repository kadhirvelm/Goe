//
//  AdventureUserDetailViewController.swift
//  Goe
//
//  Created by Kadhir M on 4/16/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class AdventureUserDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Utility helpers
    
    let goeCloudData = GoeCloudKit()
    var goeUtilities: GoeUtilities?
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    /** REQUIRED VARIABLE. User CKRecord. */
    var viewingUserDetail: CKRecord?
    /** Viewing user's profile.*/
    var viewingProfileDetail: CKRecord?
    
    //MARK: Viewing goer's details UI
    
    /** The table view where all the adventures load.*/
    @IBOutlet weak var adventuresTableView: UITableView!
    /** The blurred out background picture.*/
    @IBOutlet weak var backgroundPicture: UIImageView!
    /** The user's profile picture.*/
    @IBOutlet weak var profilePicture: UIImageView!
    /** The user's name.*/
    @IBOutlet weak var name: UILabel!
    /** The user's rating.*/
    @IBOutlet weak var rating: UILabel!
    /** The user's biography.*/
    @IBOutlet weak var bio: UILabel!
    /** The background scroll view.*/
    @IBOutlet weak var scrollView: UIScrollView!
    /** Indicates adventures are still loading.*/
    @IBOutlet weak var stillLoading: UIActivityIndicatorView!
    /** Label for mutual friends.*/
    @IBOutlet weak var mutualFriends: UILabel!
    /** Users review. */
    @IBOutlet weak var userReviewsTableView: UITableView!
    
    //MARK: Backend logistics variables. */
    
    /** All adventures this goer is attending.*/
    var allAdventures = [[CKRecord]]()
    /** All attending adventures.*/
    var attendingAdventures: [CKRecord] = []
    /** All hosting adventures.*/
    var hostingAdventures: [CKRecord] = []
    /** Entire adventure history.*/
    var adventureHistory: [CKRecord] = []
    /** Total server responses needed.*/
    var totalServerResponses = 3
    /** Header titles for the tableview.*/
    let headerTitles = ["Adventures Hosting", "Adventures Attending", "Adventure History"]
    /** Database titles for accessing data.*/
    let databaseTitles = ["Adventure_Hosting", "Adventure_Attending", "Adventure_History"]
    /** Reviews of this particular user. */
    var userReviews = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stillLoading.startAnimating()
        self.registerHeaders()
        self.goeCloudData.fetchProfile((self.viewingUserDetail?.valueForKey("ID") as? String)!, completionHandler: self.adjustTables)
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: nil, scrollView: self.scrollView)
        self.findMutualFriends()
        self.setProfileAttributes()
    }
    
    /** Sets the profile attributes of th user. */
    func setProfileAttributes() {
        /* Setting the profile picture and making it into a circle. */
        dispatch_async(dispatch_get_main_queue()) {
            let imageData = self.goeCloudData.getProfilePhoto(self.viewingUserDetail!)
            if imageData != nil {
                self.profilePicture.image = UIImage(data: imageData!)
                self.backgroundPicture.image = UIImage(data: imageData!)
            }
            self.profilePicture.layer.borderWidth = 3
            self.profilePicture.layer.borderColor = ColorConstants.Profile.profilePictureBorderColor
            self.profilePicture.layer.masksToBounds = false
            self.profilePicture.layer.cornerRadius = self.profilePicture.frame.height/2
            self.profilePicture.clipsToBounds = true
        }
        /* Setting the background image and creating the blur effect. */
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = backgroundPicture.frame
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.backgroundPicture.addSubview(blurEffectView)
        
        /* Setting the profile name. */
        let name = viewingUserDetail?.valueForKey("Name") as! String
        let tempTitle = name.characters.split{$0 == "."}.map(String.init)
        self.name.text = "\(tempTitle[0]) \(tempTitle[1])" ?? "Name"
        
        let rating = viewingUserDetail?.valueForKey("Goe_Rating") as! Int
        self.rating.text = "Goe Rating: \(rating)"
        
        var bioText = viewingUserDetail?.valueForKey("Details") as! [String]
        bio.text = bioText[0]
        goeUtilities!.setObjectHeight(self.bio, padding: 8)
        bioText.removeFirst()
        if bioText.count > 0 {
            userReviews = bioText
            UIView.transitionWithView(self.userReviewsTableView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.userReviewsTableView.reloadData()
                }, completion: nil)
        } else {
            userReviewsTableView.hidden = true
        }
    }
    
    /** Registers the profile headers. */
    func registerHeaders(){
        let nib = UINib(nibName: "ProfileTableHeader", bundle: nil)
        adventuresTableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "ProfileTableHeader")
    }
    
    /** Finds and displays mutual friends. */
    func findMutualFriends() {
        let params = NSDictionary(dictionary: [("fields" as NSObject): "context.fields(mutual_friends)"]) as [NSObject: AnyObject]
        let facebookID = viewingUserDetail?.valueForKey("Facebook_ID") as! String
        let request = FBSDKGraphRequest.init(graphPath: "/\(facebookID)", parameters: params)
        FBSDKAccessToken.refreshCurrentAccessToken { (connection, result, error) in
            request.startWithCompletionHandler { (connection, result, error) in
                if result != nil {
                    if let context = result["context"] as? [String: AnyObject] {
                        if let mutualFriends = context["mutual_friends"] as? [String: AnyObject] {
                            if let users = mutualFriends["data"] as? NSArray {
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.mutualFriends.text = "\(users.count) mutual friends"
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    /** Adjusts the tableviews with the new data. */
    func adjustTables(loggedInUserProfile: CKRecord?) {
        viewingProfileDetail = loggedInUserProfile
        clearOutArrays()
        for index in 0...2 {
            self.fetchAdventures(self.databaseTitles[index], arrayIndex: index, completionHandler: self.reloadTable)
        }
    }
    
    /** Goes through and clears out all the arrays holding adventures currently. */
    func clearOutArrays(){
        hostingAdventures.removeAll()
        attendingAdventures.removeAll()
        adventureHistory.removeAll()
        allAdventures.removeAll()
        allAdventures.append(hostingAdventures)
        allAdventures.append(attendingAdventures)
        allAdventures.append(adventureHistory)
    }
    
    /** Fetches the adventure with the given keyword and puts then in the arrayIndex of allAdventures. */
    func fetchAdventures(keywords: String, arrayIndex: Int, completionHandler: () -> Void) {
        let adventuresInQuestion = viewingProfileDetail?.valueForKey("\(keywords)") as? [CKReference] ?? []
        if adventuresInQuestion.count > 0 {
            let operationQueue = NSOperationQueue()
            for adventure in adventuresInQuestion {
                operationQueue.addOperationWithBlock({
                    let userID = CKRecordID(recordName: adventure.recordID.recordName)
                    self.publicDatabase.fetchRecordWithID(userID) { fetchedAventure, error in
                        if error == nil {
                            dispatch_async(dispatch_get_main_queue(), { 
                                self.allAdventures[arrayIndex].append(fetchedAventure!)
                                if self.allAdventures[arrayIndex].count == adventuresInQuestion.count {
                                    completionHandler()
                                }
                            })
                        } else {
                            print(error)
                            //handle error here
                        }
                    }
                })
            }
        } else {
            completionHandler()
        }
    }
    
    /** Handles the server responses and reloads the table when needed. */
    func reloadTable(){
        dispatch_async(dispatch_get_main_queue()) {
            self.totalServerResponses -= 1
            if self.totalServerResponses == 0 {
                self.changeSizesAndReload()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        goeUtilities!.setBackgroundSize()
    }
    
    /** Changes the size of the tableview to its natural size and reloads the data inside. */
    func changeSizesAndReload() {
        checkToHide()
        if adventuresTableView.hidden == false {
            NSLayoutConstraint.deactivateConstraints(self.adventuresTableView.constraints)
            UIView.transitionWithView(adventuresTableView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.adventuresTableView.reloadData()
                }, completion: self.completeChangeSizes)
        } else {
            goeUtilities!.setBackgroundSize()
            stillLoading.stopAnimating()
        }
    }
    
    func checkToHide() {
        for index in allAdventures {
            if index.count > 0 {
                return
            }
        }
        adventuresTableView.hidden = true
    }
    
    /** Adjusts the adventure table view autoformatting constraints.*/
    func completeChangeSizes(success: Bool) {
        self.adventuresTableView.sizeToFit()
        let height = self.adventuresTableView.contentSize.height
        let newConstraint = NSLayoutConstraint(item: self.adventuresTableView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: height)
        NSLayoutConstraint.activateConstraints([newConstraint])
        goeUtilities!.setBackgroundSize()
        stillLoading.stopAnimating()
    }
    
    //MARK: UITableView Delegate Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch tableView {
        case adventuresTableView:
            return allAdventures.count
        case userReviewsTableView:
            if userReviews.count > 0 {
                return 1
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case adventuresTableView:
            if allAdventures[section].count > 0 {
                return 1
            } else {
                return 0
            }
        case userReviewsTableView:
            return userReviews.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch tableView {
        case adventuresTableView:
            let title = headerTitles[section]
            let cell = self.adventuresTableView.dequeueReusableHeaderFooterViewWithIdentifier("ProfileTableHeader") as! ProfileTableHeader
            cell.headerLabel.text = title
            return cell
        case userReviewsTableView:
            let title = "User Comments"
            let cell = self.adventuresTableView.dequeueReusableHeaderFooterViewWithIdentifier("ProfileTableHeader") as! ProfileTableHeader
            cell.headerLabel.text = title
            return cell
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(30)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableView {
        case adventuresTableView:
            let cell = tableView.dequeueReusableCellWithIdentifier("AdventureCell",forIndexPath: indexPath)
            return cell
        case userReviewsTableView:
            let cell = tableView.dequeueReusableCellWithIdentifier("Review", forIndexPath: indexPath) as? UserReviewsTableViewCell
            cell?.rawReview = userReviews[indexPath.row]
            cell?.setNeedsLayout()
            return cell!
        default:
            return UITableViewCell()
        }
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        switch tableView {
        case adventuresTableView:
            guard let tableViewCell = cell as? ViewAdventurerDetails else { return }
            tableViewCell.setCollectionViewDataSourceDelegate(self, forHeight: indexPath.section, forRow: indexPath.row)
        default:
            break
        }
    }
}
