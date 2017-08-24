//
//  ChattingViewController.swift
//  Goe
//
//  Created by Kadhir M on 7/30/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import CloudKit

class ChattingViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {

    //MARK: IBOutlets
    /** Where chats are entered.*/
    @IBOutlet weak var chatTextView: UITextView!
    /** Where all the chats are displayed.*/
    @IBOutlet weak var chatsTableView: UITableView!
    /** The send button.*/
    @IBOutlet weak var sendButton: UIButton!
    /** Sending chat indicator.*/
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: Adventure Specifics
    
    /** Adventure where this chat is coming from. */
    var Adventure: CKRecord?
    /** The CKReference Chat.*/
    var Adventure_Chat: CKReference?
    /** The CKRecord Chat.*/
    var Adventure_ChatRecord: CKRecord?
    /** The chats to display.*/
    var adventureChats: [String]?
    /** The current user.*/
    var user: User?
    /** Sending indicator.*/
    var sending: Bool = false {
        didSet {
            if sending {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            sendButton.enabled = !sending
        }
    }
    /** If true, once the view appears, will refresh the chats. */
    var appearSetRefresher = true
    /** Dictionary that indicates what colors each user should be. */
    var user_color = [String: UIColor]()
    /** Holds all users currently registered in the chat. */
    var current_users: [CKReference]?
    /** Color Palette for user's chat. */
    let color_palette = [UIColorFromHex(0x7FB1B2),
                         UIColorFromHex(0xBEDCA8),
                         UIColorFromHex(0xFFAAA5),
                         UIColorFromHex(0xB1938B),
                         UIColorFromHex(0xE6DCE7),
                         UIColorFromHex(0xF5943C),
                         UIColorFromHex(0xEBD476),
                         UIColorFromHex(0xF7D842),
                         UIColorFromHex(0xB1D877),
                         UIColorFromHex(0xCCFFFF),
                         UIColorFromHex(0xFFFFCC)]
    
    //MARK: Utility Helpers
    
    /** Goe cloud kit utility.*/
    let goeCloudKitHelper = GoeCloudKit()
    /** Goe core data utility.*/
    let goeCoreDataHelper = GoeCoreData()
    /** Goe utilities helper.*/
    var goeUtilities = GoeUtilities()
    /** Public database accesser. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    //MARK: Methods Begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sendButton.setTitle("", forState: UIControlState.Disabled)
        sendButton.setTitle("Send", forState: UIControlState.Normal)
        user = goeCoreDataHelper.retrieveData("User")![0] as? User
        checkToDisableChatBox()
    }
    
    /** Checks if the chat box should be disabled, if not, sets the chats view. */
    func checkToDisableChatBox() {
        let attendingUsers = Adventure?.valueForKey("User_Attending") as? [CKReference] ?? []
        if attendingUsers.count <= 10 {
            setTextBoxUI()
            firstTimeRefreshChats()
        } else {
            chatTextView.hidden = true
            chatsTableView.hidden = true
            sendButton.hidden = true
            appearSetRefresher = false
        }
    }
    
    /** Sets the textbox UI, namely the rounded corners. */
    func setTextBoxUI() {
        chatTextView.layer.borderColor = UIColor.grayColor().CGColor
        chatTextView.layer.borderWidth = 1.0
        chatTextView.layer.cornerRadius = 5.0
    }
    
    /** Goes and fetches the chats from the database and refreshes the page.*/
    func firstTimeRefreshChats() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            if self.Adventure_Chat != nil {
                self.check_user_colors()
                self.goeCloudKitHelper.fetchReference(self.Adventure_Chat!) { (record) in
                    self.Adventure_ChatRecord = record
                    self.checkForSubscription()
                    self.adventureChats = record?.valueForKey("Chats") as? [String]
                    dispatch_async(dispatch_get_main_queue(), {
                        self.refreshTableView()
                    })
                }
            }
        }
    }
    
    /** Goes through the users who are currently attending the adventure and sets a color for each user. */
    func check_user_colors() {
        if Adventure != nil {
            let user_host = [Adventure?.valueForKey("User_Host") as! CKReference]
            let users_attending = Adventure?.valueForKey("User_Attending") as? [CKReference] ?? []
            current_users = user_host + users_attending
            for index in 0...(current_users!.count - 1) {
                user_color[(current_users![index].recordID.recordName)] = color_palette[index] ?? UIColor.grayColor()
            }
        }
    }
    
    /** Checks if the user is already subscribed to this chat. */
    func checkForSubscription() {
        publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions, error) in
            if error == nil {
                let ID = self.Adventure_ChatRecord?.valueForKey("ID") as? NSNumber
                let predicate = NSPredicate(format: "ID = \(ID!)")
                for subscription in subscriptions! {
                    if ((subscription.predicate?.isEqual(predicate)) == true) {
                        if subscription.recordType == "Adventure_Chat" {
                            return
                        }
                    }
                }
                self.createChatSubscription()
            } else {
                print("Chat Controller Error: \(error)")
            }
        }
    }
    
    /** Creates a subscription for this chat. */
    func createChatSubscription() {
        let ID = Adventure_ChatRecord?.valueForKey("ID") as! NSNumber
        let name = Adventure_ChatRecord?.valueForKey("Name") as! String
        let predicate = NSPredicate(format: "ID = \(ID)")
        let subscription = CKSubscription(recordType: "Adventure_Chat", predicate: predicate, options: .FiresOnRecordUpdate)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertLocalizationKey = name + ": New Message"
        notificationInfo.soundName = UILocalNotificationDefaultSoundName
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo
        
        publicDatabase.saveSubscription(subscription) { (subscription, error) -> Void in
            if error != nil {
                print(error)
                //handle error case here
            }
        }
    }
    
    /** Refreshes the chats. */
    func refreshChats(completionHandler: (() -> ())? = nil) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)) {
            if self.Adventure_Chat != nil {
                self.check_user_colors()
                self.goeCloudKitHelper.fetchReference(self.Adventure_Chat!) { (record) in
                    self.Adventure_ChatRecord = record
                    self.adventureChats = record?.valueForKey("Chats") as? [String]
                    dispatch_async(dispatch_get_main_queue(), {
                        self.refreshTableView(completionHandler)
                    })
                }
            }
        }
    }
    
    /** Refreshes the chats tableview. */
    func refreshTableView(completionHandler: (() -> ())? = nil) {
        self.chatsTableView.reloadData()
        if self.adventureChats?.count > 0 {
            let bottom = NSIndexPath(forItem: self.adventureChats!.count-1, inSection: 0)
            self.chatsTableView.scrollToRowAtIndexPath(bottom, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        if completionHandler != nil { completionHandler!() }
    }
    
    //MARK: Refresher handlers
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if appearSetRefresher {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.notificationRefreshChat), name: "Chat", object: nil)
        }
    }
    
    /** Handles the notification's refresh. */
    func notificationRefreshChat(notification: NSNotification) {
        refreshChats()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if appearSetRefresher {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: "Chat", object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    //MARK: Sending Functions
    
    @IBAction func Send(sender: UIButton) {
        send()
    }
    
    /** Sends whatever is in the chatTextView to the main chat. */
    func send() {
        if chatTextView.text.characters.count > 0 {
            sending = true
            refreshChats(completeSending)
        } else {
            refreshChats()
        }
    }
    
    /** Completes sending the text into the cloud after refreshing the chats. */
    func completeSending() {
        activityIndicator.startAnimating()
        let userRef = user?.user_reference
        let name = user?.user_Name
        let chatText = chatTextView.text
        let fullChat = "\(userRef!)||\(name!)||\(chatText)"
        chatTextView.text = ""
        if (adventureChats != nil){
            adventureChats?.append(fullChat)
        } else {
            adventureChats = [fullChat]
        }
        Adventure_ChatRecord!["Chats"] = adventureChats
        goeCloudKitHelper.saveRecord(Adventure_ChatRecord!) { (record) in
            dispatch_async(dispatch_get_main_queue(), {
                self.sending = false
                self.refreshChats(nil)
            })
        }
    }
    
    //MARK: TextViewDelegate
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            send()
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        sendButton.alpha = 1
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        sendButton.alpha = 0.5
    }
    
    //MARK: TableView Delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adventureChats?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("chat") as? ChatTableViewCell
        cell?.user_color = self.user_color
        cell?.rawChat = adventureChats![indexPath.row]
        cell?.setChatText(user!.user_reference!)
        return cell!
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
