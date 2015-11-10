#import "TextAnswer.h"
#import "CoreDataHelper.h"

@implementation TextAnswer

@synthesize managedObjectContext;
@synthesize currentQuestion;
@synthesize logAnswer;
@synthesize qidField, answerField;
@synthesize aPictureField;
@synthesize soundButton;
@synthesize noncurrentQuestions;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *dbString = [currentQuestion answer];
    dbString = [dbString stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    dbString = [dbString stringByReplacingOccurrencesOfString:@"<BR>" withString:@"\n"];
    [answerField setText:[dbString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"]];
        
    if (currentQuestion.aPictureName) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,     NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:[currentQuestion aPictureName]];
        UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
        
        [aPictureField  setImage:img];
        aPictureField.hidden = false;
    }
    else {
        aPictureField.hidden = true;
    }
    if (currentQuestion.aSound.length > 0)
        soundButton.hidden = false;
    else
        soundButton.hidden = true;
}

- (void)setLocalNotificationForAppleWatch:(int)dateLatency
{
    NSMutableSet *categories = [[NSMutableSet alloc] init];
    UIMutableUserNotificationAction *viewQuestion = [[UIMutableUserNotificationAction alloc] init];
    viewQuestion.title = @"View Question";
    viewQuestion.identifier = @"viewQuestion";
    viewQuestion.activationMode = UIUserNotificationActivationModeForeground;
    viewQuestion.authenticationRequired = false;
    
    UIMutableUserNotificationCategory *questionCategory = [[UIMutableUserNotificationCategory alloc] init];
    questionCategory.identifier = @"qDue";
    [questionCategory setActions:@[viewQuestion] forContext:UIUserNotificationActionContextDefault];
    
    [categories addObject:questionCategory];
    
    UIUserNotificationType notificationType = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationType categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
//    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:dateLatency];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
}

- (NSDictionary *)createAPNS:(NSString *)qid
{
    // Alert dictionary
    NSDictionary *alertDict = @{@"body":@"06/06 13:35", @"title": @"Question due"};
    
    // aps dictionary
    NSDictionary *apsDict = @{@"alert":alertDict, @"category":@"qDue"};
    
    // Dictionary with several kay/value pairs and the above array of arrays
    NSDictionary *dict = @{@"aps" : apsDict, @"message": @"06/06 13:35", @"question": @"Where do babies come from?"};
    /*
     NSError *error = nil;
     NSData *json;
     
     // Dictionary convertable to JSON ?
     if ([NSJSONSerialization isValidJSONObject:dict])
     {
     // Serialize the dictionary
     json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
     
     // If no errors, let's view the JSON
     if (json != nil && error == nil)
     {
     NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
     
     NSLog(@"JSON: %@", jsonString);
     }
     }*/
    return dict;
}

//  Answer is true
- (IBAction)answerIsTrue:(id)sender
{
    double correction;
    if (currentQuestion.correction) {
        correction = [currentQuestion.correction doubleValue];
    }
    else {
        correction = 0.0;
    }
    NSTimeInterval dateTime;
    NSTimeInterval dateLatency = [currentQuestion.nextdue timeIntervalSinceNow];
    if (currentQuestion.lastanswered){
        dateTime = [currentQuestion.lastanswered timeIntervalSinceNow];
        currentQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:fmax((2 - correction), 1.1)*fabs(dateTime)];
    }
    else {
     //   dateTime = (double)600;
        currentQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:600];
    }
    currentQuestion.lastanswered = [NSDate date];
    
    AnswerLog *logInfo = [NSEntityDescription insertNewObjectForEntityForName:@"AnswerLog" inManagedObjectContext:self.managedObjectContext];
    logInfo.qid = currentQuestion.qid;
    logInfo.dateanswered = [NSDate date];
    logInfo.accuracy = [NSNumber numberWithBool:true];
    
    NSError *error;
    
#if TARGET_IPHONE_SIMULATOR
    // where are you?
    NSLog(@"Documents Directory: %@", [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]);
#endif
    
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to save nextdue with error: %@", [error domain]);
    
    if (dateLatency<-18000)
    {
        dateLatency = (double)300;
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSInteger intVal = [prefs integerForKey:@"timeLag"];
        if (intVal>0)
            intVal = intVal - 1;
        [prefs setInteger:intVal forKey:@"timeLag"];
        [prefs synchronize];
        
        
    }
    else {
        if (dateLatency < 0) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSInteger intVal = [prefs integerForKey:@"timeLag"];
            if (intVal>0)
                intVal = intVal - 1;
            [prefs setInteger:intVal forKey:@"timeLag"];
            [prefs synchronize];
            dateLatency = (double)(600 + dateLatency/60);
        }
        else {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSInteger intVal = [prefs integerForKey:@"timeLag"];
            
            // ATTEMPT TO AUTOMATE NEW QUESTIONS; DO NEW AT TIMELAG = 10, 20, 30
            if ([prefs objectForKey:@"lastNewQuestion"]&&[prefs integerForKey:@"countNewQuestions"])
                // eg if there is a date of the last new question initiated and a count of questions initiated today
            {
                if ([[NSDateFormatter localizedStringFromDate:[prefs objectForKey:@"lastNewQuestion"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]])
                    // eg if the date of the last new question initiated is equal to today's date
                {
                    if ([prefs integerForKey:@"timeLag"]>10)
                    {
                        // Automatic initiation of new questions at timeLag = 10, 20, 30, etc, resetting each day
                        NSPersistentStoreCoordinator *psc = [managedObjectContext persistentStoreCoordinator];
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                        [newContext setPersistentStoreCoordinator:psc];
                        
                        //         NSMutableArray *nCQuestions = [[NSMutableArray alloc] init];
                        
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
                        NSMutableArray *nCQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:managedObjectContext];
                        
                        Questions *activateQuestion = [nCQuestions objectAtIndex:0];
                        
                        activateQuestion.current = [NSNumber numberWithBool:true];
                        activateQuestion.lastanswered = [NSDate dateWithTimeIntervalSinceNow:((660+60*intVal)-300)];
                        activateQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:(660+60*intVal)];
                        
                        // Add 1 to count of new questions initiated today
                        [prefs setInteger:[prefs integerForKey:@"countNewQuestions"]+1 forKey:@"countNewQuestions"];
                    }
                }
                else
                {
                    // restart count as must be a new day
                    [prefs setInteger:1 forKey:@"countNewQuestions"];
                    [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
                }
                
                /* OLD METHOD FOR TRIGGERING NEW QUESTION - NEW QUESTION FOR EACH 10 QUESTION COUNTS PER DAY
                if ([[NSDateFormatter localizedStringFromDate:[prefs objectForKey:@"lastNewQuestion"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]])
                    // eg if the date of the last new question initiated is equal to today's date
                {
                    if ([prefs integerForKey:@"timeLag"]/[prefs integerForKey:@"countNewQuestions"]>=10)
                    {
                        // Automatic initiation of new questions at timeLag = 10, 20, 30, etc, resetting each day
                        NSPersistentStoreCoordinator *psc = [managedObjectContext persistentStoreCoordinator];
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                        [newContext setPersistentStoreCoordinator:psc];
                        
               //         NSMutableArray *nCQuestions = [[NSMutableArray alloc] init];
                        
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
                        NSMutableArray *nCQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:managedObjectContext];
                        
                        Questions *activateQuestion = [nCQuestions objectAtIndex:0];
                        
                        activateQuestion.current = [NSNumber numberWithBool:true];
                        activateQuestion.lastanswered = [NSDate dateWithTimeIntervalSinceNow:((660+60*intVal)-300)];
                        activateQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:(660+60*intVal)];
                        
                        // Add 1 to count of new questions initiated today
                        [prefs setInteger:[prefs integerForKey:@"countNewQuestions"]+1 forKey:@"countNewQuestions"];
                    }
                }
                else
                {
                    // restart count as must be a new day
                    [prefs setInteger:1 forKey:@"countNewQuestions"];
                    [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
                } */
            }
            else
            {
                // eg if there is no date for the last new question initiated, or no count of questions initiated today
                [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
                [prefs setInteger:1 forKey:@"countNewQuestions"];
            }
            
            intVal = intVal + 1;
            [prefs setInteger:intVal forKey:@"timeLag"];
            [prefs synchronize];
            dateLatency = (double)(600 + 60 * intVal);
        }
    }
    
 /*   if (dateLatency > 900) {
        dateLatency = 900;
    }
   */ 
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(int)dateLatency];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger intVal = [prefs integerForKey:@"timeLag"];
    
    localNotification.alertBody = [NSString stringWithFormat:@"%ld-%d", (long)intVal, (int)dateLatency];
    localNotification.alertAction = [NSString stringWithFormat:@"View"];
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
	localNotification.alertLaunchImage = nil;
    
    localNotification.category = @"qDue";
    localNotification.userInfo = [self createAPNS:@"999"];
    [self setLocalNotificationForAppleWatch:dateLatency];
    
	// Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    [self.navigationController popViewControllerAnimated:YES];
}

//  Answer is false
- (IBAction)answerIsFalse:(id)sender
{
    NSTimeInterval dateTime;
    NSTimeInterval dateLatency = [currentQuestion.nextdue timeIntervalSinceNow];
    if (currentQuestion.lastanswered){
        dateTime = [currentQuestion.lastanswered timeIntervalSinceNow];
        currentQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:0.1*fabs(dateTime)];
    }
    else {
    //    dateTime = (double)600;
        currentQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:600];
    }
    currentQuestion.lastanswered = [NSDate date];
    
    if (currentQuestion.correction) {
        currentQuestion.correction = [NSNumber numberWithDouble:[currentQuestion.correction doubleValue] + 0.04];
    }
    
    AnswerLog *logInfo = [NSEntityDescription insertNewObjectForEntityForName:@"AnswerLog" inManagedObjectContext:self.managedObjectContext];
    logInfo.qid = currentQuestion.qid;
    logInfo.dateanswered = [NSDate date];
    logInfo.accuracy = [NSNumber numberWithBool:false];
    
    NSError *error;
    
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to save nextdue with error: %@", [error domain]);
    
    if (dateLatency<-18000)
    {
        dateLatency = (double)300;
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSInteger intVal = [prefs integerForKey:@"timeLag"];
        if (intVal>0)
            intVal = intVal - 1;
        [prefs setInteger:intVal forKey:@"timeLag"];
        [prefs synchronize];
    }
    else {
        if (dateLatency < 0) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSInteger intVal = [prefs integerForKey:@"timeLag"];
            if (intVal>0)
                intVal = intVal - 1;
            [prefs setInteger:intVal forKey:@"timeLag"];
            [prefs synchronize];
            dateLatency = (double)(600 + dateLatency/60);
        }
        else {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSInteger intVal = [prefs integerForKey:@"timeLag"];
            
            // ATTEMPT TO AUTOMATE NEW QUESTIONS; DO NEW AT TIMELAG = 10, 20, 30
            
            if ([prefs objectForKey:@"lastNewQuestion"]&&[prefs integerForKey:@"countNewQuestions"])
            // eg if there is a date of the last new question initiated and a count of questions initiated today
            {
                if ([[NSDateFormatter localizedStringFromDate:[prefs objectForKey:@"lastNewQuestion"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]])
                // eg if the date of the last new question initiated is equal to today's date
                {
                    if ([prefs integerForKey:@"timeLag"]/[prefs integerForKey:@"countNewQuestions"]>=10)
                    {
                 /*       NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
                        noncurrentQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:managedObjectContext];
                        */
                        
                        
                        // Automatic initiation of new questions at timeLag = 10, 20, 30, etc, resetting each day
                        NSPersistentStoreCoordinator *psc = [managedObjectContext persistentStoreCoordinator];
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                        [newContext setPersistentStoreCoordinator:psc];
                        
              //          NSMutableArray *nCQuestions = [[NSMutableArray alloc] init];
                        
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
                        NSMutableArray *nCQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:managedObjectContext];
                        
                        Questions *activateQuestion = [nCQuestions objectAtIndex:0];
                        
                        activateQuestion.current = [NSNumber numberWithBool:true];
                        activateQuestion.lastanswered = [NSDate dateWithTimeIntervalSinceNow:((660+60*intVal)-300)];
                        activateQuestion.nextdue = [NSDate dateWithTimeIntervalSinceNow:(660+60*intVal)];
                        
                        // Add 1 to count of new questions initiated today
                        [prefs setInteger:[prefs integerForKey:@"countNewQuestions"]+1 forKey:@"countNewQuestions"];
                    }
                }
                else
                {
                    // restart count as must be a new day; uses 1 so not dividing by 0
                    [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
                    [prefs setInteger:1 forKey:@"countNewQuestions"];
                }
            }
            else
            {
                // eg if there is no date for the last new question initiated, or no count of questions initiated today
                [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
                [prefs setInteger:1 forKey:@"countNewQuestions"];
            }
  /*          NSDate *dateNewQuestion;
            NSInteger intNewQuestionsToday;
            if ([prefs objectForKey:@"lastNewQuestion"]) {
                dateNewQuestion = [prefs objectForKey:@"lastNewQuestion"];
            }
            if ([prefs integerForKey:@"countNewQuestions"]) {
                intNewQuestionsToday = [prefs integerForKey:@"countNewQuestions"];
            }
            if (dateNewQuestion==[NSDate date]) {
                if ([prefs integerForKey:@"timeLag"]/[prefs integerForKey:@"intNewQuestionsToday"]>=10) {
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Alert Title here"
                                                                   message: @"Alert Message here"
                                                                  delegate: nil
                                                         cancelButtonTitle:@"Cancel"
                                                         otherButtonTitles:@"OK",nil];
                    
                    
                    [alert show];
                }
                if ([prefs integerForKey:@"intNewQuestionsToday"]) {
                    [prefs setInteger:[prefs integerForKey:@"intNewQuestionsToday"]+1 forKey:@"intNewQuestionsToday"];
                }
                else
                    [prefs setInteger:0 forKey:@"intNewQuestionsToday"];
            }*/
            
            // RESUME ORIGINAL
            intVal = intVal + 1;
            [prefs setInteger:intVal forKey:@"timeLag"];
            [prefs synchronize];
            
            dateLatency = (double)(600 + 60 * intVal);
        }
    }
    
/*    if (dateLatency > 1200) {
        dateLatency = 1200;
    }
  */
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to save nextdue with error: %@", [error domain]);
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:currentQuestion.nextdue dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle];
    [answerField setText:dateString];
    
    // Cancel previous notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // Set up iPhone notification
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(int)dateLatency];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger intVal = [prefs integerForKey:@"timeLag"];
    
    localNotification.alertBody = [NSString stringWithFormat:@"%ld-%d", (long)intVal, (int)dateLatency];
    localNotification.alertAction = [NSString stringWithFormat:@"View"];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
	localNotification.alertLaunchImage = nil;
    
    localNotification.category = @"qDue";
    localNotification.userInfo = [self createAPNS:@"999"];
    [self setLocalNotificationForAppleWatch:dateLatency];
    
    
	// Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)playSound:(id)sender
{
    if ([currentQuestion aSound])
    {
        NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:[currentQuestion aSound]];
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
        
        if (fileExists){
            NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",applicationDocumentsDir, [currentQuestion aSound]]];
            NSError *error;
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error]; 
            audioPlayer.numberOfLoops = 0;
            
            if (audioPlayer == nil)
                NSLog(@"%@", [error description]);
            else
                [audioPlayer play];
        }
        else {
            NSURL *url;
            NSData *data;
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://www.insideandysbrain.com/Sounds/", [currentQuestion aSound]]];
            
            data = [NSData dataWithContentsOfURL:url];
            [data writeToFile:storePath atomically:TRUE];
            NSError *error;
            
            audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];    
            audioPlayer.numberOfLoops = 0;
            
            if (audioPlayer == nil)
                NSLog(@"%@", [error description]);
            else 
                [audioPlayer play];
        }
        
    }
}



@end