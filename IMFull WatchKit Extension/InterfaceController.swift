//
//  InterfaceController.swift
//  IMFull WatchKit Extension
//
//  Created by Andrew Amos on 2/06/2015.
//  Copyright (c) 2015 University of Queensland. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    var questionOrAnswer: Bool = true
    
    let kAppGroupIdentifier = "group.com.slylie.intellimentor.documents"
    var sharedContainerURL: NSURL = NSURL()
    var docURL: NSURL?
    
    var json: JSON?
    
    var qid: String?
    
    @IBOutlet weak var questionButton: WKInterfaceButton!
    @IBOutlet weak var questionImage: WKInterfaceImage!
    @IBOutlet weak var questionLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }
    
    func refreshControls() {
        sharedContainerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(kAppGroupIdentifier)! // eg shared documents
        docURL = sharedContainerURL.URLByAppendingPathComponent("question.json")
        
        json = JSON(data: NSData(contentsOfURL: docURL!)!)
        
        qid = json!["qid"].stringValue
        
        let questionString = json!["Question"].stringValue
        
        questionLabel.setText(questionString.stringByReplacingOccurrencesOfString("<br/>", withString: "\n"))
        questionButton.setTitle("Show Answer")
        
        questionImage.setHidden(true)
        
        if json!["qImage"].stringValue == "(null)" {
            json!["qImage"].stringValue = ""
        }
        
        if json!["aImage"].stringValue == "(null)" {
            json!["aImage"].stringValue == ""
        }
        
        if (!json!["qImage"].stringValue.isEmpty) {
        //    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
            let getImagePath = sharedContainerURL.URLByAppendingPathComponent(json!["qImage"].stringValue)
            
            if let data = NSData(contentsOfURL: getImagePath) { //make sure your image in this url does exist, otherwise unwrap in a if let check            
                var img = UIImage(data: data)
                questionImage.setImage(img)
                questionImage.setHidden(false)
            }
        }
        questionOrAnswer = true
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        let requestInfo: [NSObject: AnyObject] = [NSString(string: "accuracy"): NSString(string: "start")]
        WKInterfaceController.openParentApplication(requestInfo) { (replyInfo: [NSObject: AnyObject]!, error: NSError!) -> Void in
            self.refreshControls()
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func showAnswerButton() {
        if questionOrAnswer {
            questionOrAnswer = !questionOrAnswer
            
            let answerString = json!["Answer"].stringValue
            questionLabel.setText(answerString.stringByReplacingOccurrencesOfString("<br/>", withString: "\n"))
            
            if (!json!["aImage"].stringValue.isEmpty) {
                //    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
                let getImagePath = sharedContainerURL.URLByAppendingPathComponent(json!["aImage"].stringValue)
                
                let data = NSData(contentsOfURL: getImagePath) //make sure your image in this url does exist, otherwise unwrap in a if let check
                var img = UIImage(data: data!)
                questionImage.setImage(img)
                questionImage.setHidden(false)
            } else {
                questionImage.setHidden(true)
            }
            questionButton.setTitle("Show Question")
        } else {
            questionOrAnswer = !questionOrAnswer
            
            let questionString = json!["Question"].stringValue
            questionLabel.setText(questionString.stringByReplacingOccurrencesOfString("<br/>", withString: "\n"))
            
            if (!json!["qImage"].stringValue.isEmpty) {
                //    let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
                let getImagePath = sharedContainerURL.URLByAppendingPathComponent(json!["qImage"].stringValue)
                
                let data = NSData(contentsOfURL: getImagePath) //make sure your image in this url does exist, otherwise unwrap in a if let check
                var img = UIImage(data: data!)
                questionImage.setImage(img)
                questionImage.setHidden(false)
            } else {
                questionImage.setHidden(true)
            }
            questionButton.setTitle("Show Answer")
        }
        
    }
    
    @IBAction func correctAnswer() {
        let requestInfo: [NSObject: AnyObject] = [
            "qid": qid!,
            "accuracy": "true"
        ]
        WKInterfaceController.openParentApplication(requestInfo) { (replyInfo: [NSObject: AnyObject]!, error: NSError!) -> Void in
            self.refreshControls()
        }
    }
    
    @IBAction func incorrectAnswer() {
        let requestInfo: [NSObject: AnyObject] = [NSString(string: "qid"): NSString(string: qid!), NSString(string: "accuracy"): NSString(string: "false")]
        WKInterfaceController.openParentApplication(requestInfo) { (replyInfo: [NSObject: AnyObject]!, error: NSError!) -> Void in
            self.refreshControls()
        }
    }
    
    override func handleActionWithIdentifier(identifier: String?, forLocalNotification localNotification: UILocalNotification) {
        if let userInfo = localNotification.userInfo {
            processActionWithIdentifier(identifier, withUserInfo: userInfo)
        }
    }
    
    override func handleActionWithIdentifier(identifier: String?, forRemoteNotification remoteNotification: [NSObject : AnyObject]) {
        processActionWithIdentifier(identifier, withUserInfo: remoteNotification)
    }
    
    func processActionWithIdentifier(identifier: String?, withUserInfo userInfo: [NSObject: AnyObject]) {
        pushControllerWithName("mainInterface", context: nil)
    }
}
