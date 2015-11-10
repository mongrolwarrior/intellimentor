//
//  QuestionDueNotificationController.swift
//  IMFull
//
//  Created by Andrew Amos on 6/06/2015.
//  Copyright (c) 2015 University of Queensland. All rights reserved.
//

import Foundation
import WatchKit

class QuestionDueNotificationController: WKUserNotificationInterfaceController {
    @IBOutlet weak var titleLabel: WKInterfaceLabel!
    @IBOutlet weak var messageLabel: WKInterfaceLabel!
    
    override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: (WKUserNotificationInterfaceType) -> Void) {
        if let userInfo = localNotification.userInfo {
            processNotificationWithUserInfo(userInfo, withCompletion: completionHandler)
        }
    }
    
    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: (WKUserNotificationInterfaceType) -> Void) {
       processNotificationWithUserInfo(remoteNotification, withCompletion: completionHandler)
        
    }
    
    func processNotificationWithUserInfo(userInfo: [NSObject : AnyObject], withCompletion completionHandler:(WKUserNotificationInterfaceType)->Void) {
        
        messageLabel.setHidden(true)
        if let message = userInfo["message"] as? String {
            messageLabel.setHidden(false)
            messageLabel.setText(message)
        }
        
        titleLabel.setHidden(true)
        if let title = userInfo["title"] as? String {
            titleLabel.setHidden(false)
            titleLabel.setText(title)
        }
        
        completionHandler(.Custom)
    }
}