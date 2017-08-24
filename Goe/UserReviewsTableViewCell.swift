//
//  UserReviewsTableViewCell.swift
//  Goe
//
//  Created by Kadhir M on 8/25/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit

class UserReviewsTableViewCell: UITableViewCell {
    
    /** The name of the reviewer. */
    @IBOutlet weak var name: UILabel!
    /** The review itself. */
    @IBOutlet weak var review: UILabel!
    /** Raw review made by a user. */
    var rawReview: String?
    /** Goe utilities helper. */
    var goeUtilities = GoeUtilities()
    
    /** Sets the reviews to display. */
    override func setNeedsLayout() {
        if rawReview != nil {
            let allData = rawReview!.componentsSeparatedByString("||")
            let name = goeUtilities.splitUserName(allData[1], returnname: "Last Initial")
            let date = allData[2]
            let review = allData[3]
            dispatch_async(dispatch_get_main_queue()) {
                self.name.text = "--\(name) \(date)"
                self.review.text = review
            }
        }
    }

}
