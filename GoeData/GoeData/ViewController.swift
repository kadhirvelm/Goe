//
//  ViewController.swift
//  GoeData
//
//  Created by Kadhir M on 6/24/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var activity_indicator: UIActivityIndicatorView!
    let publicDatabase = CKContainer(identifier: "iCloud.com.GoeAdventure.Goe").publicCloudDatabase

    @IBOutlet weak var current_progress: UILabel!
    @IBOutlet weak var histories: UIButton!
    @IBOutlet weak var adventures: UIButton!
    @IBOutlet weak var profiles: UIButton!
    @IBOutlet weak var users: UIButton!
    @IBOutlet weak var fetch_all: UIButton!
    
    let TOTAL_DATA_SETS = 4
    
    func change_all_buttons() {
        histories.enabled = !histories.enabled
        adventures.enabled = !adventures.enabled
        profiles.enabled = !profiles.enabled
        users.enabled = !users.enabled
        fetch_all.enabled = !fetch_all.enabled
    }
    
    @IBAction func fetch_adventures(sender: UIButton) {
        change_all_buttons()
        activity_indicator.startAnimating()
        queryDatabase("Adventure", completionHandler: create_adventure_csv_file, secondHandler: completed_one_run)
    }
    
    @IBAction func fetch_histories(sender: UIButton) {
        change_all_buttons()
        activity_indicator.startAnimating()
        queryDatabase("Adventure_History", completionHandler: create_history_csv_file, secondHandler: completed_one_run)
    }
    
    @IBAction func fetch_profiles(sender: UIButton) {
        change_all_buttons()
        activity_indicator.startAnimating()
        queryDatabase("Profile", completionHandler: create_profile_csv_file, secondHandler: completed_one_run)
    }
    
    @IBAction func fetch_users(sender: UIButton) {
        change_all_buttons()
        activity_indicator.startAnimating()
        queryDatabase("User", completionHandler: create_user_csv_file, secondHandler: completed_one_run)
    }
    
    @IBAction func fetch_all(sender: UIButton) {
        change_all_buttons()
        activity_indicator.startAnimating()
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            self.queryDatabase("Adventure", completionHandler: self.create_adventure_csv_file, secondHandler: self.completed_multiple_runs)
            self.queryDatabase("Adventure_History", completionHandler: self.create_history_csv_file, secondHandler: self.completed_multiple_runs)
            self.queryDatabase("Profile", completionHandler: self.create_profile_csv_file, secondHandler: self.completed_multiple_runs)
            self.queryDatabase("User", completionHandler: self.create_user_csv_file, secondHandler: self.completed_multiple_runs)
        }
    }
    
    /* Given a userID, goes and fetches the associated user's Profile. */
    func queryDatabase(data_type: String, completionHandler: ([CKRecord]?, (String, String)-> Void) -> Void, secondHandler: (String, String) -> Void) {
        current_progress.text = "Querying Database for \(data_type), "
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let query = CKQuery(recordType: data_type, predicate: NSPredicate(format: "TRUEPREDICATE"))
            self.publicDatabase.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
                if error == nil {
                    if records?.count > 0 {
                        completionHandler(records!, secondHandler)
                    } else {
                        completionHandler(nil, secondHandler)
                    }
                } else {
                    print(error)
                }
            }
        }
    }
    
    func create_adventure_csv_file(allRecord: [CKRecord]?, completionHandler: (String, String) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            self.current_progress.text = "\(self.current_progress.text!)Successfully fetched adventures, "
        })
        var contents_of_file = "Adventure Reference,Adventure ID,Adventure Name,Adventure Description,Post Date,Adventure Date,Post/Adventure Difference,Start Time,End Time,Duration,Adventure Host ID,No. Spots,Users Attending,Users Requesting\n"
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        let time_formatter = NSDateFormatter()
        time_formatter.dateFormat = "hh:mm"
        
        if allRecord != nil {
            for record in allRecord! {
                let adventure_reference = record.recordID.recordName
                let adventure_ID = record.valueForKey("ID") as! Int
                let adventure_name = record.valueForKey("Name") as! String
                let adventure_description = record.valueForKey("Description") as! String
                let post_date = record.creationDate!
                let adventure_date = record.valueForKey("Start_Date") as! NSDate
                let post_adventure_difference = adventure_date.offsetFrom(post_date)
                let start_time = time_formatter.stringFromDate(adventure_date)
                let end_date = record.valueForKey("End_Date") as! NSDate
                let adventure_duration = end_date.offsetFrom(adventure_date)
                let adventure_host = (record.valueForKey("User_Host") as! CKReference).recordID.recordName
                let number_spots = record.valueForKey("Spots") as! Int
                let users_accepted = flattenList(record.valueForKey("User_Attending") as? [CKReference])
                let users_requesting = flattenList(record.valueForKey("User_Requesting") as? [CKReference])
                
                let post_date_final = formatter.stringFromDate(post_date).stringByReplacingOccurrencesOfString(",", withString: "")
                let adventure_date_final = formatter.stringFromDate(adventure_date).stringByReplacingOccurrencesOfString(",", withString: "")
                let end_date_final = formatter.stringFromDate(end_date).stringByReplacingOccurrencesOfString(",", withString: "")
                dispatch_async(dispatch_get_main_queue(), {
                    self.current_progress.text = "\(self.current_progress.text!) \((allRecord?.indexOf(record))!), "
                })
                contents_of_file = "\(contents_of_file)\(adventure_reference),\(adventure_ID),\(adventure_name),\(adventure_description),\(post_date_final),\(adventure_date_final),\(post_adventure_difference),\(start_time),\(end_date_final),\(adventure_duration),\(adventure_host),\(number_spots),\(users_accepted),\(users_requesting)\n"
            }
        }
        completionHandler(contents_of_file, "Adventure_Data.csv")
    }
    
    func create_history_csv_file(allRecord: [CKRecord]?, completionHandler: (String, String) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            self.current_progress.text = "\(self.current_progress.text!)Successfully fetched history, "
        })
        var contents_of_file = "Adventure ID,Adventure Name,Host User,Users Attended,Ratings\n"
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        let time_formatter = NSDateFormatter()
        time_formatter.dateFormat = "hh:mm"
        
        if allRecord != nil {
            for record in allRecord! {
                let adventure_ID = record.valueForKey("ID") as! Int
                let adventure_name = record.valueForKey("Name") as! String
                let host = (record.valueForKey("User_Host") as! CKReference).recordID.recordName
                let attended = flattenList((record.valueForKey("User_Attended") as? [CKReference]))
                let ratings = flattenList((record.valueForKey("Ratings") as! [Double]))
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.current_progress.text = "\(self.current_progress.text!) \((allRecord?.indexOf(record))!), "
                })
                contents_of_file = "\(contents_of_file)\(adventure_ID),\(adventure_name),\(host),\(attended),\(ratings)\n"
            }
        }
        completionHandler(contents_of_file, "History_Data.csv")
    }
    
    func create_profile_csv_file(allRecord: [CKRecord]?, completionHandler: (String, String) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            self.current_progress.text = "\(self.current_progress.text!)Successfully fetched profile, "
        })
        var contents_of_file = "User Reference,User ID,Adventures Attending References,Adventures Completed References,Adventure History References,Adventures Hosting References,Adventures Rejected References\n"
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        let time_formatter = NSDateFormatter()
        time_formatter.dateFormat = "hh:mm"
        
        if allRecord != nil {
            for record in allRecord! {
                let user_reference = record.recordID.recordName
                let user_ID = record.valueForKey("User_ID") as! String
                let attending = flattenList(record.valueForKey("Adventure_Attending") as? [CKReference])
                let completed = flattenList(record.valueForKey("Adventure_Completed") as? [CKReference])
                let history = flattenList(record.valueForKey("Adventure_History") as? [CKReference])
                let hosting = flattenList(record.valueForKey("Adventure_Hosting") as? [CKReference])
                let rejected = flattenList(record.valueForKey("Adventure_Rejected") as? [CKReference])
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.current_progress.text = "\(self.current_progress.text!) \((allRecord?.indexOf(record))!), "
                })
                contents_of_file = "\(contents_of_file)\(user_reference),\(user_ID),\(attending),\(completed),\(history),\(hosting),\(rejected)\n"
            }
        }
        completionHandler(contents_of_file, "Profile_Data.csv")
    }
    
    func create_user_csv_file(allRecord: [CKRecord]?, completionHandler: (String, String) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            self.current_progress.text = "\(self.current_progress.text!)Successfully fetched users, "
        })
        var contents_of_file = "User Reference,User ID,Facebook ID,Name,Details,Goe Rating,Status,Email,\n"
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        
        let time_formatter = NSDateFormatter()
        time_formatter.dateFormat = "hh:mm"
        
        if allRecord != nil {
            for record in allRecord! {
                let user_reference = record.recordID.recordName
                let user_ID = record.valueForKey("ID") as! String
                let facebook_ID = record.valueForKey("Facebook_ID") as! String
                let name = record.valueForKey("Name") as! String
                let details = flattenList(record.valueForKey("Details") as? [String])
                let rating = record.valueForKey("Goe_Rating") as! Int
                let status = record.valueForKey("Status") as! Int
                let email = record.valueForKey("Email") as? String ?? "None"
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.current_progress.text = "\(self.current_progress.text!) \((allRecord?.indexOf(record))!), "
                })
                contents_of_file = "\(contents_of_file)\(user_reference),\(user_ID),\(facebook_ID),\(name),\(details),\(rating),\(status),\(email)\n"
            }
        }
        completionHandler(contents_of_file, "Users_Data.csv")
    }
    
    func completed_one_run(contents_of_file: String, file_name: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.current_progress.text = "\(self.current_progress.text!)Done"
            self.activity_indicator.stopAnimating()
        })
        let final_path = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(file_name)
        do {
            try contents_of_file.writeToURL(final_path, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            self.current_progress.text = "- SAVING ERRORS -"
        }
        self.send_email([file_name])
    }
    
    var all_files = [String]()
    func completed_multiple_runs(contents_of_file: String, file_name: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.current_progress.text = "\(self.current_progress.text!)\(file_name) Done, "
            self.all_files.append(file_name)
            let final_path = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(file_name)
            do {
                try contents_of_file.writeToURL(final_path, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                self.current_progress.text = "- SAVING ERRORS -"
            }
            if self.all_files.count == self.TOTAL_DATA_SETS {
                self.activity_indicator.stopAnimating()
                self.send_email(self.all_files)
            }
        })
    }
    
    func send_email(file_name: [String]) {
        let emailController = MFMailComposeViewController()
        emailController.setSubject("Goe Adventure CSV Data")
        emailController.mailComposeDelegate = self
        emailController.setMessageBody("Requested data is attached.", isHTML: false)
        
        for file in file_name {
            let final_path = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(file)
            emailController.addAttachmentData(NSData(contentsOfURL: final_path)!, mimeType: "text/csv", fileName: file)
        }
        
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(emailController, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        current_progress.text = ""
        change_all_buttons()
        all_files.removeAll()
    }
    
    //MARK: HELPER FUNCTIONS
    
    func flattenList(reference_list: [CKReference]?)->String {
        var final_string = ""
        if reference_list != nil{
            for reference in reference_list! {
                final_string = "\(final_string) \(reference.recordID.recordName)"
            }
        }
        return final_string
    }
    
    @nonobjc func flattenList(double_list: [Double]?)->String {
        var final_string = ""
        if double_list != nil{
            for number in double_list! {
                final_string = "\(final_string) \(number)"
            }
        }
        return final_string
    }
    
    @nonobjc func flattenList(string_list: [String]?)->String {
        var final_string = ""
        if string_list != nil{
            for string in string_list! {
                final_string = "\(final_string) \(string.stringByReplacingOccurrencesOfString(",", withString: ""))"
            }
        }
        return final_string
    }
}

extension NSDate {
    
    func offsetFrom(date:NSDate) -> String {
        
        let dayHourMinuteSecond: NSCalendarUnit = [.Day, .Hour, .Minute, .Second]
        let difference = NSCalendar.currentCalendar().components(dayHourMinuteSecond, fromDate: date, toDate: self, options: [])
        
        let minutes = "\(difference.minute)m"
        let hours = "\(difference.hour)h" + " " + minutes
        let days = "\(difference.day)d" + " " + hours
        
        return days
    }
    
}

