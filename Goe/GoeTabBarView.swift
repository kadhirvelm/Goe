//
//  GoeTabBarView.swift
//  Goe
//
//  Created by Kadhir M on 5/21/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit

class GoeTabBarView: UITabBar {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 35
        return sizeThatFits
    }

}
