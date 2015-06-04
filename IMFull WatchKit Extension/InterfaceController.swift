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
        sharedContainerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(kAppGroupIdentifier)!
        docURL = sharedContainerURL.URLByAppendingPathComponent("question.json")
        
        json = JSON(data: NSData(contentsOfURL: docURL!)!)
        
        qid = json!["qid"].stringValue
        
        questionLabel.setText(json!["Question"].stringValue)
        questionButton.setTitle("Show Answer")
        
        questionImage.setHidden(true)
        
        if (!json!["qImage"].stringValue.isEmpty) {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
            let getImagePath = documentsPath.stringByAppendingPathComponent(json!["qImage"].stringValue)
            let img = UIImage(contentsOfFile: getImagePath)
            questionImage.setImage(img)
            questionImage.setHidden(false)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        /*
        NSString *kAppGroupIdentifier = @"group.com.slylie.intellimentor.documents";
        NSURL *sharedContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
        NSURL *docURL = [sharedContainerURL URLByAppendingPathComponent:@"question.json"];
        
        BOOL ok = [@"{\"Question\": \"This is the question?\", \"Answer\": \"This is the answer.\"}" writeToURL:docURL atomically:YES encoding:NSUTF8StringEncoding error:nil];*/
        self.refreshControls()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func showAnswerButton() {
        if questionOrAnswer {
            questionOrAnswer = !questionOrAnswer
            questionLabel.setText(json!["Answer"].stringValue)
            
            if (!json!["aImage"].stringValue.isEmpty) {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
                let getImagePath = documentsPath.stringByAppendingPathComponent(json!["aImage"].stringValue)
                let img = UIImage(contentsOfFile: getImagePath)
                questionImage.setImage(img)
                questionImage.setHidden(false)
            } else {
                questionImage.setHidden(true)
            }
            questionButton.setTitle("Show Question")
        } else {
            questionOrAnswer = !questionOrAnswer
            questionLabel.setText(json!["Question"].stringValue)
            if (!json!["qImage"].stringValue.isEmpty) {
                let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
                let getImagePath = documentsPath.stringByAppendingPathComponent(json!["qImage"].stringValue)
                let img = UIImage(contentsOfFile: getImagePath)
                questionImage.setImage(img)
                questionImage.setHidden(false)
            } else {
                questionImage.setHidden(true)
            }
            questionButton.setTitle("Show Answer")
        }
        
    }
    
    @IBAction func correctAnswer() {
        let qidString = "qid"
        let requestInfo: [NSObject: AnyObject] = [NSString(string: "qid"): NSString(string: qid!), NSString(string: "accuracy"): NSString(string: "true")]
        WKInterfaceController.openParentApplication(requestInfo) { (replyInfo: [NSObject: AnyObject]!, error: NSError!) -> Void in
            self.refreshControls()
        }
    }
    
    @IBAction func incorrectAnswer() {
        let qidString = "qid"
        let requestInfo: [NSObject: AnyObject] = [NSString(string: "qid"): NSString(string: qid!), NSString(string: "accuracy"): NSString(string: "false")]
        WKInterfaceController.openParentApplication(requestInfo) { (replyInfo: [NSObject: AnyObject]!, error: NSError!) -> Void in
            self.refreshControls()
        }
    }
}
