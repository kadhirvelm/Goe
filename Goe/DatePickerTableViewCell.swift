//
//  DatePickerTableView.swift
//  Goe
//
//  Created by Kadhir M on 6/7/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit

class DatePickerTableViewCell: UITableViewCell {
    
    //Return to comment, this will take time to understand
    
    var isObserving = false
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var DatePicker: UIDatePicker!
    
    let formatter = NSDateFormatter()
    
    @IBAction func DateChanged(sender: UIDatePicker) {
        setCellDate(sender.date)
    }
    
    func setCellDate(sender: NSDate) {
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = .ShortStyle
        date.text = formatter.stringFromDate(sender)
    }
    
    class var expandedHeight: CGFloat { get { return 200 } }
    class var defaultHeight: CGFloat  { get { return 44  } }
    
    func checkHeight() {
        DatePicker.hidden = (frame.size.height < DatePickerTableViewCell.expandedHeight)
    }
    
    func watchFrameChanges() {
        if !isObserving {
            addObserver(self, forKeyPath: "frame", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: nil)
            isObserving = true;
        }
    }
    
    func ignoreFrameChanges() {
        if isObserving {
            setCellDate(DatePicker.date)
            removeObserver(self, forKeyPath: "frame")
            isObserving = false;
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "frame" {
            checkHeight()
        }
    }

}
