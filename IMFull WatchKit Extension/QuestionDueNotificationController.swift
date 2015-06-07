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
 
    @IBOutlet weak var questionLabel: WKInterfaceLabel!
    
    override func didReceiveLocalNotification(localNotification: UILocalNotification, withCompletion completionHandler: (WKUserNotificationInterfaceType) -> Void) {
        if let userInfo = localNotification.userInfo {
            processNotificationWithUserInfo(userInfo, withCompletion: completionHandler)
        }
    }
    
    override func didReceiveRemoteNotification(remoteNotification: [NSObject : AnyObject], withCompletion completionHandler: (WKUserNotificationInterfaceType) -> Void) {
        processNotificationWithUserInfo(remoteNotification, withCompletion: completionHandler)
    }
    
    func processNotificationWithUserInfo(userInfo: [NSObject : AnyObject], withCompletion completionHandler:(WKUserNotificationInterfaceType)->Void) {
        
        questionLabel.setHidden(true)
        if let title = userInfo["question"] as? String {
            questionLabel.setHidden(false)
            questionLabel.setText(title)
        }
        
        completionHandler(.Custom)
    }    
}