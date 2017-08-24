//
//  ViewAdventurerDetails.swift
//  Goe
//
//  Created by Kadhir M on 4/17/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit

class ViewAdventurerDetails: UITableViewCell {
    
    @IBOutlet weak var actualCollectionView: UICollectionView!
    
    /** Sets the collectionview data sources and other information needed for displaying. */
    func setCollectionViewDataSourceDelegate <D: protocol<UICollectionViewDataSource, UICollectionViewDelegate>>(dataSourceDelegate: D, forHeight section: Int, forRow row: Int) {
        
        actualCollectionView.delegate = dataSourceDelegate
        actualCollectionView.dataSource = dataSourceDelegate
        actualCollectionView.tag = section
        actualCollectionView.reloadData()
    }
}

extension AdventureUserDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return allAdventures[collectionView.tag].count
    }
    
    func collectionView(collectionView: UICollectionView,
                        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AdventureCell",
                                                                         forIndexPath: indexPath) as? ViewingAdventurerDetailCell
        if allAdventures[collectionView.tag].count > 0 {
            let specificAdventure = allAdventures[collectionView.tag][indexPath.row]
            let imagePhotoData = goeCloudData.getAdventurePhoto(specificAdventure)
            if imagePhotoData != nil {
                cell?.AdventureImageView.image = UIImage(data: imagePhotoData!)
            }
            cell?.AdventureName.text = specificAdventure.valueForKey("Name") as? String
        }
        cell?.layer.borderColor = UIColor.blackColor().CGColor
        cell?.layer.borderWidth = 1
        cell?.layer.cornerRadius = 8
        return cell!
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        if allAdventures[collectionView.tag].count == 1 {
            let imageWidth = collectionView.frame.width * 0.718
            let inset = (scrollView.frame.width - imageWidth)/2
            return UIEdgeInsetsMake(0, inset, 0, inset)
        }
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
}
