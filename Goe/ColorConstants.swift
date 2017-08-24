//
//  ColorConstants.swift
//  Goe iPhone App
//
//  Created by Kadhir M on 1/10/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit

struct ColorConstants {
    
    static let navigationBarTintColor = UIColorFromHex(0xED8C72)
    
    struct Profile {
        static let profileViewBackground = Colors.dimmedBackground
        static let profilePictureBorderColor = Colors.dimmedHighligt.CGColor
        static let profileText = Colors.textColor
        static let indicatorColor = Colors.highlightColor
        static let tableHeaderColor = Colors.darkBackground
        static let tableHeaderText = Colors.dimmedBackground
        
    }
    
    struct Adventure {
        static let separatorColor = Colors.darkBackground
        static let tableBackground = Colors.dimmedBackground
        static let allTextColor = Colors.textColor
        static let specialText = Colors.highlightColor
    }
    
    struct Manage {
        static let mainScreenBackground = Colors.dimmedBackground
        static let mainScreenButtons = Colors.textColor
        static let mainScreenButtonsPressed = Colors.highlightColor
    }
}

func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0) -> UIColor {
    let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
    let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
    let blue = CGFloat(rgbValue & 0xFF)/256.0
    return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
}

private struct Colors {
    static let highlightColor = UIColorFromHex(0xDE7A22)
    static let dimmedHighligt = UIColorFromHex(0x6AB187)
    static let dimmedBackground = UIColorFromHex(0xC4DFE6)
    static let darkBackground = UIColorFromHex(0x20948B)
    static let textColor = UIColorFromHex(0x000B29)
}