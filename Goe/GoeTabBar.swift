//
//  GoeTabBar.swift
//  Goe
//
//  Created by Kadhir M on 5/21/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit

class GoeTabBar: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        var tabFrame = self.tabBar.frame
        tabFrame.size.height = 35
        tabFrame.origin.y = self.view.frame.size.height - 35
        self.tabBar.frame = tabFrame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
