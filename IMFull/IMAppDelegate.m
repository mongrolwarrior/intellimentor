//
//  IMAppDelegate.m
//  IMFull
//
//  Created by Andrew Amos on 3/08/12.
//  Copyright (c) 2012 University of Queensland. All rights reserved.
//

#import "IMAppDelegate.h"
#import "Users.h" 
#import "LoginViewController.h"
#import "CoreDataHelper.h"
#import "Questions.h"
#import "AnswerLog.h"

@implementation IMAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Pass the managed object context to the root view controller (the login view)
    LoginViewController *rootView = (LoginViewController *)self.window.rootViewController;
    rootView.managedObjectContext = self.managedObjectContext;
    
    // Get a reference to the stardard user defaults
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    // Check if the app has run before by checking a key in user defaults
    if ([prefs boolForKey:@"hasRunBefore"] != YES)
    {
        // Set flag so we know not to run this next time
        [prefs setBool:YES forKey:@"hasRunBefore"];
        [prefs synchronize];
        
        // Add our default user object in Core Data
        Users *user = (Users *)[NSEntityDescription insertNewObjectForEntityForName:@"Users" inManagedObjectContext:self.managedObjectContext];
        [user setName:@"admin"];
        [user setPassword:@"password"];
        
        // Commit to core data
        NSError *error;
        if (![self.managedObjectContext save:&error])
            NSLog(@"Failed to add default user with error: %@", [error domain]);
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"IMFull" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"IMFull.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply
{
    NSString *kAppGroupIdentifier = @"group.com.slylie.intellimentor.documents";
    NSURL *sharedContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    NSURL *docURL = [sharedContainerURL URLByAppendingPathComponent:@"question.json"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"qid == %d", [(NSString *)userInfo[@"qid"] integerValue]];
    NSMutableArray *questionListData = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"nextdue" andSortAscending:YES andContext:self.managedObjectContext];
    
    Questions *newQuestion = questionListData[0];
    if ([userInfo[@"accuracy"]  isEqual: @"true"])
        [self answerIsTrue:newQuestion];
    else
        [self answerIsFalse:newQuestion];
    
    predicate = [NSPredicate predicateWithFormat:@"current == YES"];
    questionListData = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"nextdue" andSortAscending:YES andContext:self.managedObjectContext];
    
    newQuestion = questionListData[0];
    
    BOOL ok = [[NSString stringWithFormat:@"{\"Question\": \"%@\", \"qImage\": \"%@\", \"Answer\": \"%@\", \"aImage\": \"%@\", \"qid\": \"%@\"}", newQuestion.question, newQuestion.qPictureName, newQuestion.answer, newQuestion.aPictureName, newQuestion.qid] writeToURL:docURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


//  Answer is true
- (void)answerIsTrue:(Questions *)currentQuestion
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
                        // Automatic initiation of new questions at timeLag = 10, 20, 30, etc, resetting each day
                        NSPersistentStoreCoordinator *psc = [self.managedObjectContext persistentStoreCoordinator];
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] init];
                        [newContext setPersistentStoreCoordinator:psc];
                        
                        //         NSMutableArray *nCQuestions = [[NSMutableArray alloc] init];
                        
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
                        NSMutableArray *nCQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:self.managedObjectContext];
                        
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
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(int)dateLatency];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger intVal = [prefs integerForKey:@"timeLag"];
    
    localNotification.alertBody = [NSString stringWithFormat:@"%d-%d", intVal, (int)dateLatency];
    localNotification.alertAction = [NSString stringWithFormat:@"View"];
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    localNotification.alertLaunchImage = nil;
    
    // Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

//  Answer is false
- (void)answerIsFalse:(Questions *)currentQuestion
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
                        NSPersistentStoreCoordinator *psc = [self.managedObjectContext persistentStoreCoordinator];
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] init];
                        [newContext setPersistentStoreCoordinator:psc];
                        
                        //          NSMutableArray *nCQuestions = [[NSMutableArray alloc] init];
                        
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
                        NSMutableArray *nCQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:self.managedObjectContext];
                        
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
    
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to save nextdue with error: %@", [error domain]);
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:currentQuestion.nextdue dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(int)dateLatency];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger intVal = [prefs integerForKey:@"timeLag"];
    
    localNotification.alertBody = [NSString stringWithFormat:@"%d-%d", intVal, (int)dateLatency];
    localNotification.alertAction = [NSString stringWithFormat:@"View"];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    localNotification.alertLaunchImage = nil;
    
    // Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


@end
