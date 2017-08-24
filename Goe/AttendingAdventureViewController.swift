//
//  AttendingAdventureViewController.swift
//  Goe
//
//  Created by Kadhir M on 7/16/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import EventKit

class AttendingAdventureViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    /* REQUIRED VARIABLE.*/
    var Adventure: CKRecord?
    
    //MARK: Adventure Specifics UI
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var spotsLeft: UILabel!
    @IBOutlet weak var adventureTitle: UILabel!
    @IBOutlet var background: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var Date: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var AdventuringUsersCollectionView: UICollectionView!
    @IBOutlet weak var cost: UILabel!
    @IBOutlet weak var equipment: UILabel!
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var usersLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyLogo: UIImageView!
    
    //MARK: Utility Helpers
    
    /** Public database helper. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    /** Goe core data helper. */
    let goeCoreData = GoeCoreData()
    /** Goe cloud kit helper. */
    let goeCloudData = GoeCloudKit()
    /** Utilties helper function. */
    var goeUtilities = GoeUtilities()
    /** Goe map container delegate. */
    var goeMapDelegate: GoeMapContainerDelegate?
    
    //MARK: Adventure Nonspecific Items
    
    /** The selected user to display. */
    var selectedUser: CKRecord?
    /** All adventuring users. */
    var AdventuringUsers = [[CKRecord?]]()
    /** The host user. */
    var hostingUser = [CKRecord?]()
    /** All attending users. */
    var attendingUsers = [CKRecord?]()
    /** Total server responses needed. */
    var totalServerResponses = 2
    
    //MARK: Methods Begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setParameters()
        self.gatherAllAdventuringUsers()
        self.goeUtilities = GoeUtilities(viewController: self, navigationController: self.navigationController!, scrollView: self.scrollView)
        self.goeUtilities.setKeyboardObservers()
        self.adjustBackground()
    }
    
    /** Loads the adventure parameters onto the UI. */
    func setParameters() {
        if let adventurePhoto = Adventure?.valueForKey("Photo") as? CKAsset {
            let url = adventurePhoto.fileURL
            let imagedata = NSData(contentsOfFile: url.path!)
            if imagedata != nil {
                photo.image = UIImage(data: imagedata!)
            }
        }
        spotsLeft.text = "Number of Spots left: \((Adventure?.valueForKey("Spots") as? Int)!)"
        adventureTitle.text = Adventure?.valueForKey("Name") as? String
        descriptionText.text = Adventure?.valueForKey("Description") as? String ?? "None"
        let startDate = NSDateFormatter.localizedStringFromDate((Adventure?.valueForKey("Start_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        let endDate = NSDateFormatter.localizedStringFromDate((Adventure?.valueForKey("End_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        Date.text = "\(startDate) - \(endDate)"
        cost.text = Adventure?.valueForKey("Estimated_Cost") as? String
        equipment.text = Adventure?.valueForKey("Equipment") as? String
        category.text = Adventure?.valueForKey("Category") as? String ?? ""
        let logo = Adventure?.valueForKey("Logo") as? CKAsset
        if logo != nil {
            let logo = goeCloudData.changeAssetToImage(logo!)
            if logo != nil {
                companyLogo?.image = logo!
            }
        }
    }
    
    /** Sets the background size to fit the content. */
    func adjustBackground() {
        self.goeUtilities.setObjectHeight(self.descriptionText, padding: 35)
        self.goeUtilities.setObjectHeight(self.equipment, padding: 8)
        self.goeUtilities.setBackgroundSize()
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
                    }, completion: { (action) in self.usersLoadingIndicator.stopAnimating() })
            }
        }
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.goeMapDelegate?.enableEditing(false)
        setMapItems()
    }
    
    /** Given the map delegate, will go through and set the proper parameters for the map. */
    func setMapItems() {
        goeMapDelegate!.mapRendezvous(Adventure?.valueForKey("String_Origin") as! String, coordinates: Adventure?.valueForKey("Origin") as? CLLocation, textEntryEnabled: false)
        goeMapDelegate!.mapDestination(Adventure?.valueForKey("String_Destination") as! String, coordinates: Adventure?.valueForKey("Destination") as? CLLocation, textEntryEnabled: false)
    }
    
    @IBAction func scrollToChat(sender: UIButton) {
        goeUtilities.slideToExtreme(false)
    }
    
    //MARK: Collection View Delegate Methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return AdventuringUsers.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AdventuringUsers[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = AdventuringUsersCollectionView.dequeueReusableCellWithReuseIdentifier("UserCell", forIndexPath: indexPath) as! UserCell
        let name = AdventuringUsers[indexPath.section][indexPath.row]!.valueForKey("Name") as? String
        let tempTitle = name!.characters.split{$0 == "."}.map(String.init)
        cell.Name.text = tempTitle[0]
        let tempProfilePicData = goeCloudData.getProfilePhoto(AdventuringUsers[indexPath.section][indexPath.row]!)
        if tempProfilePicData != nil {
            cell.ProfilePicture.image = UIImage(data: tempProfilePicData!)
        }
        let host_reference = (Adventure?.valueForKey("User_Host") as? CKReference)?.recordID.recordName
        let curr_user = (AdventuringUsers[indexPath.section][indexPath.row])?.recordID.recordName
        if (host_reference == curr_user) {
            cell.host.text = "Host"
        } else {
            cell.host.text = ""
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedUser = AdventuringUsers[indexPath.section][indexPath.row]
        self.performSegueWithIdentifier("ShowUserDetail", sender: self)
    }
    
    //MARK: Segue Methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is AdventureUserDetailViewController {
            let destination = segue.destinationViewController as? AdventureUserDetailViewController
            destination?.viewingUserDetail = selectedUser
        } else if let destination = segue.destinationViewController as? ChattingViewController {
            destination.Adventure_Chat = Adventure?.valueForKey("Adventure_Chat") as? CKReference
            destination.goeUtilities = self.goeUtilities
            destination.Adventure = self.Adventure
        } else if let destination = segue.destinationViewController as? MapViewController {
            self.goeMapDelegate = destination
        }
    }
}

