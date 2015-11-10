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
#import <AudioToolbox/AudioToolbox.h>

@implementation IMAppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    SystemSoundID sound1;
    
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"Growl" withExtension:@"wav"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[soundURL path]]) {
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(soundURL), &sound1);
        
        AudioServicesPlayAlertSound(sound1);
        
    //    AudioServicesRemoveSystemSoundCompletion(sound1);
    //    AudioServicesDisposeSystemSoundID(sound1);
    }
    
}
/*
- (NSDictionary *)createAPNS:(NSString *)qid
{
    // Alert dictionary
    NSDictionary *alertDict = @{@"body":@"Question due", @"title": @"Question due"};
    
    // aps dictionary
    NSDictionary *apsDict = @{@"alert":alertDict, @"category":@"qDue"};
    
    // Dictionary with several kay/value pairs and the above array of arrays
    NSDictionary *dict = @{@"aps" : apsDict, @"message": @"06/06 13:35", @"question": @"Where do babies come from?"};
  
    return dict;
}*/

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
    
    // Register Notification to allow custom notification on apple watch, as per: http://basememara.com/creating-notifications-from-watchkit-in-swift/
    // Notification category
    
    UIMutableUserNotificationCategory *mainCategory = [[UIMutableUserNotificationCategory alloc] init];
    mainCategory.identifier = @"qDue";
    
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:[NSSet setWithObjects:mainCategory, nil]]];
    
    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
        
        NSError *error;
        [session updateApplicationContext:@{@"firstItem": @"item1", @"secondItem":[NSNumber numberWithInt:2]} error:&error];
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
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}


-(void)processJsonFile
{
    NSString *kAppGroupIdentifier = @"group.com.slylie.intellimentor.documents";
    NSURL *sharedContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    NSURL *docURL = [sharedContainerURL URLByAppendingPathComponent:@"question.json"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == YES"];
    NSMutableArray *questionListData = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"nextdue" andSortAscending:YES andContext:self.managedObjectContext];
    
    Questions *newQuestion;
    
    for (int i=0; i<15; i++) {
        Questions *loopQuestion = questionListData[i];
        
        NSComparisonResult result = [[NSDate date] compare:loopQuestion.nextdue]; // comparing two dates; will be NSOrderedAscending if nextdue is later than now
        
        if(!(result==NSOrderedAscending && [[NSDateFormatter localizedStringFromDate:loopQuestion.lastanswered dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]]))
            // if not (next due in future, and last answered is today's date) can ask question in apple watch
        {
            newQuestion = loopQuestion;
            break;
        }
    }
    
    NSString *questionString = [newQuestion.question stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *qStringCR = [questionString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    NSString *answerString = [newQuestion.answer stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *aStringCR = [answerString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
    BOOL ok = [[NSString stringWithFormat:@"{\"Question\": \"%@\", \"qImage\": \"%@\", \"Answer\": \"%@\", \"aImage\": \"%@\", \"qid\": \"%@\"}", qStringCR, newQuestion.qPictureName, aStringCR, newQuestion.aPictureName, newQuestion.qid] writeToURL:docURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (!ok)
        NSLog(@"Failed to write question.json file in IMAppDelegate.m - handleWatchKitExtensionRequest");
    if (newQuestion.qPictureName.length > 0) {
        NSString *questionPicturePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:[@"/" stringByAppendingString:newQuestion.qPictureName]];
        NSURL *questionPictureURL = [NSURL fileURLWithPath:questionPicturePath];
        
        BOOL questionPictureExists = [questionPictureURL checkResourceIsReachableAndReturnError:nil];
        
        if (questionPictureExists){
            NSError *error;
            NSURL *fileInSharedContainerURL = [sharedContainerURL URLByAppendingPathComponent:newQuestion.qPictureName];
            BOOL success = [[NSFileManager defaultManager] copyItemAtURL:questionPictureURL toURL:fileInSharedContainerURL error:&error];
            NSLog(@"storeURL: %@", questionPicturePath);
            NSLog(@"sharedContainerURL: %@", sharedContainerURL);
            if (success == YES)
            {
                NSLog(@"Copied");
            }
            else
            {
                NSLog(@"Not Copied %@", error);
            }
        }
    }
    
    if (newQuestion.aPictureName.length > 0)
    {
        NSString *answerPicturePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:[@"/" stringByAppendingString:newQuestion.aPictureName]];
        NSURL *answerPictureURL = [NSURL fileURLWithPath:answerPicturePath];
        
        BOOL answerPictureExists = [answerPictureURL checkResourceIsReachableAndReturnError:nil];
        
        if (answerPictureExists){
            NSError *error;
            NSURL *fileInSharedContainerURL = [sharedContainerURL URLByAppendingPathComponent:newQuestion.aPictureName];
            BOOL success = [[NSFileManager defaultManager] copyItemAtURL:answerPictureURL toURL:fileInSharedContainerURL error:&error];
            NSLog(@"storeURL: %@", answerPicturePath);
            NSLog(@"sharedContainerURL: %@", sharedContainerURL);
            if (success == YES)
            {
                NSLog(@"Copied");
            }
            else
            {
                NSLog(@"Not Copied %@", error);
            }
        }
    }
    
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

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary *)userInfo replyHandler:(nonnull void (^)(NSDictionary * __nonnull))replyHandler
{
    // Temporary fix, I hope.
    // --------------------
    __block UIBackgroundTaskIdentifier bogusWorkaroundTask;
    bogusWorkaroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bogusWorkaroundTask];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endBackgroundTask:bogusWorkaroundTask];
    });
    // --------------------
    
    __block UIBackgroundTaskIdentifier realBackgroundTask;
    realBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSDictionary *fakeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Value", @"Yes", nil];
        replyHandler(fakeDictionary);
        [[UIApplication sharedApplication] endBackgroundTask:realBackgroundTask];
    }];
    
    // Kick off a network request, heavy processing work, etc.
    
    // Return any data you need to, obviously.
    
    
    NSString *kAppGroupIdentifier = @"group.com.slylie.intellimentor.documents";
    NSURL *sharedContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    NSURL *docURL = [sharedContainerURL URLByAppendingPathComponent:@"question.json"];
    NSMutableArray *questionListData;
    NSPredicate *predicate;
    Questions *newQuestion;
    
    BOOL jsonFileExists = [docURL checkResourceIsReachableAndReturnError:nil];
    
    if (jsonFileExists && ([userInfo[@"accuracy"] isEqual: @"true"] || [userInfo[@"accuracy"] isEqual:@"false"] || [userInfo[@"accuracy"] isEqual:@"delete"])) {
        predicate = [NSPredicate predicateWithFormat:@"qid == %d", [(NSString *)userInfo[@"qid"] integerValue]];
        questionListData = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"nextdue" andSortAscending:YES andContext:self.managedObjectContext];
        
        newQuestion = questionListData[0];
        if ([userInfo[@"accuracy"]  isEqual: @"true"])
            [self answerIsTrue:newQuestion];
        else if ([userInfo[@"accuracy"]  isEqual: @"false"])
            [self answerIsFalse:newQuestion];
        else if ([userInfo[@"accuracy"] isEqual: @"delete"])
            [self deleteQuestion:newQuestion];
    }
    
    [self processJsonFile];
    
    NSDictionary *fakeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"Value", @"Yes", nil];
    replyHandler(fakeDictionary);
    [[UIApplication sharedApplication] endBackgroundTask:realBackgroundTask];
}

//- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply
/*
- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary *)userInfo reply:(nonnull void (^)(NSDictionary * __nonnull))reply 
{
    // Temporary fix, I hope.
    // --------------------
    __block UIBackgroundTaskIdentifier bogusWorkaroundTask;
    bogusWorkaroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bogusWorkaroundTask];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] endBackgroundTask:bogusWorkaroundTask];
    });
    // --------------------
    
    __block UIBackgroundTaskIdentifier realBackgroundTask;
    realBackgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        reply(nil);
        [[UIApplication sharedApplication] endBackgroundTask:realBackgroundTask];
    }];
    
    // Kick off a network request, heavy processing work, etc.
    
    // Return any data you need to, obviously.
    
    
    NSString *kAppGroupIdentifier = @"group.com.slylie.intellimentor.documents";
    NSURL *sharedContainerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroupIdentifier];
    NSURL *docURL = [sharedContainerURL URLByAppendingPathComponent:@"question.json"];
    NSMutableArray *questionListData;
    NSPredicate *predicate;
    Questions *newQuestion;
    
    BOOL jsonFileExists = [docURL checkResourceIsReachableAndReturnError:nil];
    
    if (jsonFileExists && ([userInfo[@"accuracy"] isEqual: @"true"] || [userInfo[@"accuracy"] isEqual:@"false"] || [userInfo[@"accuracy"] isEqual:@"delete"])) {
        predicate = [NSPredicate predicateWithFormat:@"qid == %d", [(NSString *)userInfo[@"qid"] integerValue]];
        questionListData = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"nextdue" andSortAscending:YES andContext:self.managedObjectContext];
        
        newQuestion = questionListData[0];
        if ([userInfo[@"accuracy"]  isEqual: @"true"])
            [self answerIsTrue:newQuestion];
        else if ([userInfo[@"accuracy"]  isEqual: @"false"])
            [self answerIsFalse:newQuestion];
        else if ([userInfo[@"accuracy"] isEqual: @"delete"])
            [self deleteQuestion:newQuestion];
    }
    
    [self processJsonFile];
    
    reply(nil);
    [[UIApplication sharedApplication] endBackgroundTask:realBackgroundTask];
}*/

- (void)setLocalNotificationForAppleWatch:(int)dateLatency
{
    NSMutableSet *categories = [[NSMutableSet alloc] init];
    UIMutableUserNotificationAction *viewQuestion = [[UIMutableUserNotificationAction alloc] init];
    viewQuestion.title = @"View Question";
    viewQuestion.identifier = @"viewQuestion";
    viewQuestion.activationMode = UIUserNotificationActivationModeForeground;
    viewQuestion.authenticationRequired = false;
    
    UIMutableUserNotificationCategory *questionCategory = [[UIMutableUserNotificationCategory alloc] init];
    [questionCategory setActions:@[viewQuestion] forContext:UIUserNotificationActionContextDefault];
    questionCategory.identifier = @"qDue";
    
    [categories addObject:questionCategory];
    
    UIUserNotificationType notificationType = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:notificationType categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:dateLatency];
    
    localNotification.category = @"qDue";
 //   localNotification.userInfo = [self createAPNS:@"999"];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)deleteQuestion:(Questions *)currentQuestion
{
    NSPersistentStoreCoordinator *psc = [self.managedObjectContext persistentStoreCoordinator];
    NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [newContext setPersistentStoreCoordinator:psc];
    
    //          NSMutableArray *nCQuestions = [[NSMutableArray alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"qid == %@", currentQuestion.qid];
    NSMutableArray *nCQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:self.managedObjectContext];
    
    Questions *questionToDelete = [nCQuestions objectAtIndex:0];
    [self.managedObjectContext deleteObject:questionToDelete];
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
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
    
/*    if (dateLatency > 1200) {
        dateLatency = 1200;
    }
  */
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:(int)dateLatency];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger intVal = [prefs integerForKey:@"timeLag"];
    
    localNotification.alertBody = [NSString stringWithFormat:@"%ld-%ld", (long)intVal, (long)dateLatency];
    localNotification.alertAction = [NSString stringWithFormat:@"View"];
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    localNotification.alertLaunchImage = nil;
    
    localNotification.category = @"qDue";
//    localNotification.userInfo = [self createAPNS:@"999"];
    [self setLocalNotificationForAppleWatch:dateLatency];
    
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
                        // Automatic initiation of new questions at timeLag = 10, 20, 30, etc, resetting each day
                        NSPersistentStoreCoordinator *psc = [self.managedObjectContext persistentStoreCoordinator];
                        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
            
            // RESUME ORIGINAL
            intVal = intVal + 1;
            [prefs setInteger:intVal forKey:@"timeLag"];
            [prefs synchronize];
            
            dateLatency = (double)(600 + 60 * intVal);
        }
    }
    
 /*   if (dateLatency > 1200) {
        dateLatency = 1200;
    }
   */ 
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to save nextdue with error: %@", [error domain]);
    
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
//    localNotification.userInfo = [self createAPNS:@"999"];
    [self setLocalNotificationForAppleWatch:dateLatency];
    
    // Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
