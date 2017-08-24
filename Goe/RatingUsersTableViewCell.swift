//
//  RatingUsersTableViewCell.swift
//  Goe
//
//  Created by Kadhir M on 8/24/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import CloudKit

class RatingUsersTableViewCell: UITableViewCell, UITextViewDelegate {

    //MARK: IBOutlets
    
    /** Profile picture for the user. */
    @IBOutlet weak var profileImage: UIImageView!
    /** User's name. */
    @IBOutlet weak var username: UILabel!
    /** User review text view. */
    @IBOutlet weak var userReview: UITextView!
    /** Attended adventure indicator. */
    @IBOutlet weak var attended: UIButton!
    /** Indicates which state the attended button is in. */
    var attendedIndicator = true
    /** Was prepared indicator. */
    @IBOutlet weak var wasPrepared: UIButton!
    /** Indicates which state the wasPrepared button is in. */
    var wasPreparedIndicator = true
    /** Black cover. */
    @IBOutlet weak var black: UIView!
    /** White cover. */
    @IBOutlet weak var white: UIView!
    /** Current user. */
    var user: CKRecord?
    /** Goe utility helpers. */
    var indexPath: NSIndexPath?
    /** Delegate methods. */
    var delegate: RatingUsersCellScroll?
    
    //MARK: Rating User Table View Cell Specifics
    
    /** Image indicating negative. */
    let xMark = UIImage(named: "XMark")
    /** Image indicating positive. */
    let checkMark = UIImage(named: "CheckMark")

    @IBAction func change(sender: UIButton) {
        var finalIndicator: Bool?
        if sender == attended {
            attendedIndicator = !attendedIndicator
            finalIndicator = attendedIndicator
        } else {
            wasPreparedIndicator = !wasPreparedIndicator
            finalIndicator = wasPreparedIndicator
        }
        dispatch_async(dispatch_get_main_queue()) {
            UIView.transitionWithView(sender, duration: 0.12, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                sender.imageView?.image = (finalIndicator! ? self.checkMark : self.xMark)
                }, completion: nil)
        }
    }
    
    /** Sets the layout for the tableview cell. */
    override func setNeedsLayout() {
        profileImage.layer.borderWidth = 3
        profileImage.layer.borderColor = ColorConstants.Profile.profilePictureBorderColor
        black.layer.masksToBounds = false
        white.layer.masksToBounds = false
        profileImage.layer.masksToBounds = false
        profileImage.clipsToBounds = true
        self.bringSubviewToFront(username)
    }
    
    //MARK: Text View Delegate
    
    func textViewDidBeginEditing(textView: UITextView) {
        delegate?.selectedIndexPath(self.indexPath!)
        if textView.text == "Say something about \(username.text!)" {
            textView.text = ""
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

protocol RatingUsersCellScroll {
    func selectedIndexPath(path: NSIndexPath)
}
