//
//  ChatTableViewCell.swift
//  Goe
//
//  Created by Kadhir M on 7/30/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    /** The name of the person texting.*/
    @IBOutlet weak var name: UILabel!
    /** The chat itself.*/
    @IBOutlet weak var chat: UILabel!
    /** Chat background color. */
    @IBOutlet weak var chatBackground: UIView!
    
    /** The raw chat string. */
    var rawChat: String?
    /** Chat user's ID. */
    var ref: String?
    /** Dictionary that indicates what colors each user should be. */
    var user_color: [String: UIColor]?
    
    /** Adjusts the text box to the UI parameters, and if setOtherSender is true, creates that UI as well. */
    func setChatText(ref: String) {
        chatBackground.layer.cornerRadius = 10
        chat.clipsToBounds = true
        setChatText()
        setSenderFormatting(self.ref! != ref)
    }
    
    /** Goes through and converts rawChat into the appropriate format. */
    private func setChatText() {
        let chatsSeparated = rawChat!.componentsSeparatedByString("||")
        let ref = chatsSeparated[0]
        self.ref = ref
        let first_last = chatsSeparated[1].componentsSeparatedByString(".")
        let last = first_last[1].startIndex
        let text = chatsSeparated[2]
        
        chat.text = text
        let fixedWidth = chat.frame.size.width
        chat.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        name.text = "\(first_last[0]) \(first_last[1][last])."
    }
    
    /** Sets the chat formatting for a chat. */
    func setSenderFormatting(current_sender: Bool = false) {
        name.textAlignment = NSTextAlignment.Left
        chat.textAlignment = NSTextAlignment.Left
        if user_color![self.ref!] != nil {
            chatBackground.layer.backgroundColor =  user_color![self.ref!]!.CGColor ?? UIColorFromHex(0xB3B3B3).CGColor
        } else if current_sender{
            chatBackground.layer.backgroundColor = UIColorFromHex(0x0080FF).CGColor
            chat.textColor = UIColor.whiteColor()
        } else {
            chatBackground.layer.backgroundColor =  UIColorFromHex(0xB3B3B3).CGColor
        }
        
        chat.textColor = UIColor.blackColor()
    }
}