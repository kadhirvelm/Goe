//
//  AdventuresViewController.swift
//  Goe
//
//  Created by Kadhir M on 1/16/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class AdventuresViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /** Adventures table view where all adventures load. YOSHI.*/
    @IBOutlet weak var adventuresTableView: UITableView!
    /** The refresh controller for the tableview.*/
    var refreshControl: UIRefreshControl?
    /** All indexed adventures.*/
    var indexedCKRecords = [CKRecord]()
    /** Updates when an adventure is clicked on. */
    var adventureCellClickedOn: CKRecord?
    /** The current logged in user. */
    var loggedInUser: User?
    
    //MARK: Goe utility helpers
    /** Cloud kit helper. */
    let goeCloudKit = GoeCloudKit()
    /** Core data helper. */
    let goeCoreData = GoeCoreData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl!.attributedTitle = NSAttributedString(string: "Refreshing...")
        self.refreshControl!.addTarget(self, action: #selector(AdventuresViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        let tempLoggedInUser = goeCoreData.retrieveData("User")
        loggedInUser = tempLoggedInUser![0] as? User
        self.adventuresTableView.addSubview(self.refreshControl!)
        dispatch_async(dispatch_get_main_queue()) {
            self.adventuresTableView.setContentOffset(CGPointMake(0,-self.refreshControl!.frame.size.height), animated: true)
            self.updateTable()
        }
    }
    
    /** Refresh control handler. */
    func refresh(sender: AnyObject) {
        updateTable()
    }
    
    /** Updates the table with the latest adventures. */
    func updateTable() {
        self.refreshControl!.beginRefreshing()
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        //Return to adjust based on user's location
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            let date = NSDate()
            let predicate = NSPredicate(format: "Start_Date > %@", date)
            let query = CKQuery(recordType: "Adventure", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "Start_Date", ascending: true)]
            publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if error == nil {
                    if self.indexedCKRecords != records! {
                        self.indexedCKRecords = records!
                        self.removePastAdventures(self.indexedCKRecords, completionHandler: self.reloadData)
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.refreshControl!.endRefreshing()
                        })
                    }
                } else {
                    print(error)
                    //handle error here
                }
            }
        }
    }
    
    /** Remove all adventures taking place in the past. */
    func removePastAdventures(records: [CKRecord], completionHandler: () -> Void) {
        var final_records = records
        for adventure in records {
            if (adventure.valueForKey("Start_Date") as! NSDate).compare(NSDate()).rawValue != 1 {
                final_records.removeFirst()
            } else {
                break
            }
        }
        self.indexedCKRecords = final_records
        completionHandler()
    }
    
    /** Reloads the data in the table. */
    func reloadData() {
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshControl!.endRefreshing()
            UIView.transitionWithView(self.adventuresTableView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.adventuresTableView.reloadData()
                }, completion: nil)
        })
    }
    
    //MARK: Table View Delegate Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return indexedCKRecords.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.adventuresTableView.dequeueReusableCellWithIdentifier("AdventureTableCell") as! AdventureTableViewCell
        cell.adventureTitle.text = String(indexedCKRecords[indexPath.row].valueForKey("Name") as! NSString)
        let tempImageData = goeCloudKit.getAdventurePhoto(indexedCKRecords[indexPath.row])
        if tempImageData != nil {
            cell.adventureImage.image = UIImage(data: tempImageData!)
        }
        let startDate = NSDateFormatter.localizedStringFromDate((indexedCKRecords[indexPath.row].valueForKey("Start_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        let endDate = NSDateFormatter.localizedStringFromDate((indexedCKRecords[indexPath.row].valueForKey("End_Date") as? NSDate)!, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)
        cell.Date.text = "\(startDate) - \(endDate)"
        cell.numberOfSpots.text = "Spots: \((indexedCKRecords[indexPath.row].valueForKey("Spots") as? NSNumber)!)"
        let userReference = indexedCKRecords[indexPath.row].valueForKey("User_Host") as! CKReference
        if userReference.recordID.recordName == self.loggedInUser?.user_reference {
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColorFromHex(0x000080).CGColor
        } else {
            cell.layer.borderWidth = 0.0
        }
        let logo = indexedCKRecords[indexPath.row].valueForKey("Logo") as? CKAsset
        if logo != nil {
            let companyLogo = goeCloudKit.changeAssetToImage(logo!)
            if companyLogo != nil {
                cell.companyLogo.image = companyLogo!
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        adventuresTableView.deselectRowAtIndexPath(indexPath, animated: true)
        adventureCellClickedOn = indexedCKRecords[indexPath.row]
        performSegueWithIdentifier("ShowClickedOnAdventureDetail", sender: self)
    }
    
    //MARK: Segue Methods
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? AdventureDetailViewController {
            destination.Adventure = adventureCellClickedOn!
        } else if let destination = segue.destinationViewController as? AttendingAdventureViewController {
            destination.Adventure = adventureCellClickedOn!
        }
    }
}
