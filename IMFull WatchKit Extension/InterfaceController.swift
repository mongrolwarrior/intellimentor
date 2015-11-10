//
//  InterfaceController.swift
//  IMFull WatchKit Extension
//
//  Created by Andrew Amos on 2/06/2015.
//  Copyright (c) 2015 University of Queensland. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    var answerIsHidden = true
    var session: WCSession!
    var currentQid: NSNumber?
    
    let kAppGroupIdentifier = "group.com.slylie.intellimentor.documents"
    var sharedContainerURL: NSURL = NSURL()
    var docURL: NSURL?
    
    var json: JSON?
    
    var qid: String?
    
    @IBOutlet weak var questionButton: WKInterfaceButton!
    @IBOutlet weak var questionImage: WKInterfaceImage!
    @IBOutlet weak var questionLabel: WKInterfaceLabel!
    @IBOutlet var answerLabel: WKInterfaceLabel!
    @IBOutlet var nextDueDate: WKInterfaceLabel!
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }
    
    func sendAnswerToiPhone(accuracy: Bool) {
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
        
        var answerData: [String: AnyObject] = ["messageType": "sendAnswer"]
        answerData["accuracy"] = accuracy
        
        if self.currentQid != nil {
            answerData["qid"] = currentQid
        }
        
        session.sendMessage(answerData, replyHandler: {(reply: [String : AnyObject]) -> Void in
            if let nextDue = reply["nextdue"] as? String
            {
                self.setNextDueDisplay(nextDue)
            }
            }, errorHandler:
            {
                (error ) -> Void in
                // catch any errors here
            }
        )
        getQuestionFromiPhone()
    }

    
    func setNextDueDisplay(nextDue: String) {
        self.nextDueDate.setHidden(false)
        self.nextDueDate.setText(nextDue)
    }
    


    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.getQuestionFromiPhone()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func deleteCurrentQuestion() {
     /*   let requestInfo: [String: AnyObject] = [
            "qid": qid!,
            "accuracy": "delete"
        ]
        
        session.sendMessage(requestInfo, replyHandler: {(_: [String : AnyObject]) -> Void in
            self.refreshControls()
            }, errorHandler:  {(error ) -> Void in
                
        })
        
        /*WKInterfaceController.openParentApplication(requestInfo) { (replyInfo: [NSObject: AnyObject], error: NSError?) -> Void in
            self.refreshControls()
        }*/*/
    }
    
    @IBAction func showAnswerButton() {
        if answerIsHidden {
            questionButton.setTitle("Show Question")
            answerLabel.setHidden(false)
            questionImage.setHidden(false)
        } else {
            questionButton.setTitle("Show Answer")
            answerLabel.setHidden(true)
        }
        answerIsHidden = !answerIsHidden
    }
    
    @IBAction func correctAnswer() {
      sendAnswerToiPhone(true)
    }
    
    @IBAction func incorrectAnswer() {
     sendAnswerToiPhone(false)
    }
    
    override func handleActionWithIdentifier(identifier: String?, forLocalNotification localNotification: UILocalNotification) {
//        pushControllerWithName("mainInterface", context: nil)
    }
    
    override func handleActionWithIdentifier(identifier: String?, forRemoteNotification remoteNotification: [NSObject : AnyObject]) {
//        pushControllerWithName("mainInterface", context: nil)
    }
    
    func processActionWithIdentifier(identifier: String?, withUserInfo userInfo: [NSObject: AnyObject]) {
 //       pushControllerWithName("mainInterface", context: nil)
    }
    
    func getQuestionFromiPhone() {
        if (WCSession.isSupported()) {
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
        }
        
        let applicationData = ["messageType": "getQuestion"]
        
        session.sendMessage(applicationData, replyHandler: {(reply: [String : AnyObject]) -> Void in
            if let question = reply["question"] as? String,
                let answer = reply["answer"] as? String,
                let qImage = reply["qImage"] as? String,
                let aImage = reply["aImage"] as? String,
                let qid = reply["qid"] as? NSNumber
            {
                self.setDisplay(question, answer: answer, qImage: qImage, aImage: aImage)
                self.currentQid = qid
            }
            }, errorHandler:
            {
                (error ) -> Void in
                // catch any errors here
            }
        )
    }
    
    func setDisplay(question: String, answer: String, qImage: String, aImage: String) {
        questionImage.setImage(nil)
        questionImage.setHidden(true)
        if !question.isEmpty {
            self.questionLabel.setHidden(false)
            self.questionLabel.setText(question)
        } else {
            self.questionLabel.setHidden(true)
        }
        if !answer.isEmpty {
            self.answerLabel.setText(answer)
        } else {
            self.answerLabel.setHidden(true)
        }
        if !qImage.isEmpty {
            var qImageNew = qImage.stringByReplacingOccurrencesOfString(".svg", withString: "")
            qImageNew = qImageNew.stringByReplacingOccurrencesOfString(".gif", withString: "")
            questionImage.setImageNamed(qImageNew)
            questionImage.setHidden(false)
        }
        if !aImage.isEmpty {
            var aImageNew = aImage.stringByReplacingOccurrencesOfString(".svg", withString: "")
            aImageNew = aImageNew.stringByReplacingOccurrencesOfString(".gif", withString: "")
            questionImage.setImageNamed(aImageNew)
            questionImage.setHidden(true)
        }
        self.answerLabel.setHidden(true)
        answerIsHidden = true
    }
    

}
