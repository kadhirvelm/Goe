//
//  ProfileTableViewCell.swift
//  Goe
//
//  Created by Kadhir M on 4/11/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class ProfileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var actualCollectionView: UICollectionView!

    func setCollectionViewDataSourceDelegate <D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>(dataSourceDelegate: D, forHeight section: Int, forRow row: Int) {
        actualCollectionView.delegate = dataSourceDelegate
        actualCollectionView.dataSource = dataSourceDelegate
        actualCollectionView.tag = section
        actualCollectionView.reloadData()
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return allAdventures2[collectionView.tag].count
    }
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("Adventure Cell",
                                                                         forIndexPath: indexPath) as? ProfileAdventureCell
        if allAdventures2[collectionView.tag].count > 0 {
            let specificAdventure = allAdventures2[collectionView.tag][indexPath.row]
            let imagePhotoData = goeCloudData.getAdventurePhoto(specificAdventure)
            if imagePhotoData != nil {
                cell?.imageView.image = UIImage(data: imagePhotoData!)
            }
            cell?.adventureTitle.text = specificAdventure.valueForKey("Name") as? String
            cell = determineIfHost(cell!, specificAdventure: specificAdventure)
        }
        
        cell?.layer.borderColor = UIColor.blackColor().CGColor
        cell?.layer.borderWidth = 1
        cell?.layer.cornerRadius = 8
        return cell!
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        if allAdventures2[collectionView.tag].count == 1 {
            let imageWidth = collectionView.frame.width * 0.718
            let inset = (scrollViewBackground.frame.width - imageWidth)/2
            return UIEdgeInsetsMake(0, inset, 0, inset)
        }
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    /** Determines if the current user is hosting the adventure and sets the requests text accordingly. */
    func determineIfHost(cell: ProfileAdventureCell, specificAdventure: CKRecord) -> ProfileAdventureCell {
        let hostingAdventure: Bool = ((specificAdventure.valueForKey("User_Host") as? CKReference)?.recordID.recordName == self.loggedInUser?.user_reference)
        let pastDate = (specificAdventure.valueForKey("End_Date") as? NSDate)!.compare(NSDate()).rawValue == 1
        let isAdventureType = ("Adventure" == specificAdventure.recordType)
        cell.requests.hidden = !(hostingAdventure && pastDate && isAdventureType)
        if (!cell.requests.hidden) {
            let numRequests = (specificAdventure.valueForKey("User_Requesting") as? [CKReference])?.count
            if numRequests != nil {
                cell.requests.text = "Requests: \(numRequests!)"
            } else {
                cell.requests.text = "Requests: \(0)"
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedCell = allAdventures2[collectionView.tag][indexPath.row]
        if headerTitles[collectionView.tag] != "History" {
            if headerTitles[collectionView.tag] == "Unavailable" {
                self.deleteSelectedAdventure()
            } else {
                performSegueWithIdentifier(headerTitles[collectionView.tag], sender: self)
            }
        }
    }
}