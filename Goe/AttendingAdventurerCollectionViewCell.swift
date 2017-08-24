//
//  AttendingAdventurerCollectionViewCell.swift
//  Goe
//
//  Created by Kadhir M on 7/7/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit

class AttendingAdventurerCollectionViewCell: UICollectionViewCell {
    
    /** Requesting user name.*/
    @IBOutlet weak var Name: UILabel!
    /** Requesting user profile picture.*/
    @IBOutlet weak var ProfilePicture: UIImageView!
    /** Black tint over profile picture.*/
    @IBOutlet weak var black: UIView!
    /** White tint over profile picture.*/
    @IBOutlet weak var white: UIView!
    
    /** Changes the shape of the profile picture and tints to be circular. */
    override func setNeedsLayout() {
        ProfilePicture.layer.borderWidth = 3
        ProfilePicture.layer.borderColor = ColorConstants.Profile.profilePictureBorderColor
        black.layer.masksToBounds = false
        white.layer.masksToBounds = false
        ProfilePicture.layer.masksToBounds = false
        ProfilePicture.layer.cornerRadius = self.frame.height/2
        black.layer.cornerRadius = self.frame.height/2
        white.layer.cornerRadius = self.frame.height/2
        ProfilePicture.clipsToBounds = true
        self.bringSubviewToFront(Name)
    }
}
