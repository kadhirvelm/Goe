//
//  UserCell.swift
//  Goe
//
//  Created by Kadhir M on 4/16/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit

class UserCell: UICollectionViewCell {
    
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var ProfilePicture: UIImageView!
    @IBOutlet weak var black: UIView!
    @IBOutlet weak var white: UIView!
    @IBOutlet weak var host: UILabel!
    
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
    }
}
