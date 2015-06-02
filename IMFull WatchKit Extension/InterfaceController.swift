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
    @IBOutlet weak var questionLabel: WKInterfaceLabel!
    @IBOutlet weak var answerLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        /*
        NSString *kAppGroupIdentifier = @"group.com.slylie.intellimentor.documents";
        NSURL *sharedContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
        NSURL *docURL = [sharedContainerURL URLByAppendingPathComponent:@"question.json"];
        
        BOOL ok = [@"{\"Question\": \"This is the question?\", \"Answer\": \"This is the answer.\"}" writeToURL:docURL atomically:YES encoding:NSUTF8StringEncoding error:nil];*/
        
        let kAppGroupIdentifier = "group.com.slylie.intellimentor.documents"
        let sharedContainerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(kAppGroupIdentifier)
        let docURL = sharedContainerURL?.URLByAppendingPathComponent("question.json")
        
        let json = JSON(data: NSData(contentsOfURL: docURL!)!)
        
        questionLabel.setText(json["Question"].stringValue)
        answerLabel.setText(json["Answer"].stringValue)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
