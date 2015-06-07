#import "IMMainTable.h"
#import "CoreDataHelper.h"
#import "Questions.h"
#import "QuestionDetail.h"
#import "TextQuestion.h"
#import "NewQuestionVC.h"

@implementation IMMainTable

@synthesize managedObjectContext, questionListData;
@synthesize filteredSearchArray;
@synthesize questionSearchBar;

NSTimer *timer;

//  When the view reappears, read new data for table
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
  //  Use these to reset date and counter for automatic new question
  //  [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
  //  [prefs setInteger:1 forKey:@"countNewQuestions"];
    self.navigationItem.title = [NSString stringWithFormat:@"%ld-%ld", (long)[prefs integerForKey:@"countNewQuestions"], (long)[prefs integerForKey:@"timeLag"]];
    //  Repopulate the array with new table data
    [self readDataForTable];
    // Repeat populate every second
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(readDataForTable) userInfo:nil repeats:YES];
    // replaced by NSTIME repeating function above - "[self readDataForTable];"
    
    [self processJsonFile];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [timer invalidate];
}

//  Grab data for table - this will be used whenever the list appears or reappears after an add/edit
- (void)readDataForTable
{
    //  Grab the data
 //   NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-20000];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == YES"];
    questionListData = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"nextdue" andSortAscending:YES andContext:managedObjectContext]; 
 //   questionListData = [CoreDataHelper getObjectsForEntity:@"Questions" withSortKey:@"nextdue" andSortAscending:YES andContext:managedObjectContext];
    
    //  Force table refresh
    [self.tableView reloadData];
}

#pragma mark - Actions

//  Button to log out of app (dismiss the modal view!)
- (IBAction)logoutButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
   // deprecated form [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

//  Return the number of sections in the table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//  Return the number of rows in the section (the amount of items in our array)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.	searchDisplayController.searchResultsTableView) {
        return [filteredSearchArray count];
    } else {
        return [questionListData count];
    }
}

//  Create / reuse a table cell and configure it for display
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Get the core data object we need to use to populate this table cell
    Questions *currentCell = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        currentCell = [filteredSearchArray objectAtIndex:indexPath.row];
    } else {
        currentCell = [questionListData objectAtIndex:indexPath.row];
    }
    
    //  Fill in the cell contents
    NSString *dateString;
    if (currentCell.nextdue) {
        dateString = [NSDateFormatter localizedStringFromDate:currentCell.nextdue dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle];
    }
    else {
        dateString = @"No next due date";
    }
    
    cell.textLabel.text = dateString;
    
    cell.detailTextLabel.text = [currentCell question];
    
    // If question has never been answered "false" correction string below will be 0
    NSString *numStr = [NSString stringWithFormat:@"%@",currentCell.correction];
    
    NSComparisonResult result;
    //has three possible values: NSOrderedSame,NSOrderedDescending, NSOrderedAscending
    
    NSDate *NowDate = [NSDate date];
    
    result = [NowDate compare:currentCell.nextdue]; // comparing two dates; will be NSOrderedAscending if nextdue is later than now
    
    // Next two lines are necessary because otherwise cells remain greyed on return from question view
    cell.textLabel.enabled = YES;
    cell.detailTextLabel.enabled = YES;    
    
    if([numStr  isEqual: @"0"] && result==NSOrderedAscending && [[NSDateFormatter localizedStringFromDate:currentCell.lastanswered dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]]) // eg if never false, nextdue in future, and lastanswered date equals today's date
    {
        //    cell.userInteractionEnabled = NO;  // If you want to disable interaction with the cell
        cell.textLabel.enabled = NO;
        cell.detailTextLabel.enabled = NO;
    }
    
    if(![numStr isEqualToString:@"0"] && result==NSOrderedAscending && [[NSDateFormatter localizedStringFromDate:currentCell.lastanswered dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]])
        // if correction is not 0 (and therefore there has been an incorrect answer), next due in future, and last answered is today's date; this greys out questions that have been incorrectly answered today
    {
        //    cell.userInteractionEnabled = NO;  // If you want to disable interaction with the cell
        cell.textLabel.enabled = NO;
        cell.detailTextLabel.enabled = NO;
    }
    
    //  If a picture exists then use it
    if ([currentCell qPictureName])
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:[currentCell qPictureName]];
        UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
        
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.image = img;
    }
    else {
        cell.imageView.image = NULL;
    }
    
    return cell;
}

//  Swipe to delete has been used.  Remove the table item
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        //  Get a reference to the table item in our data array
        Questions *itemToDelete = [self.questionListData objectAtIndex:indexPath.row];
        
        //  Delete the item in Core Data
        [self.managedObjectContext deleteObject:itemToDelete];
        
        //  Remove the item from our array
        [questionListData removeObjectAtIndex:indexPath.row];
        
        //  Commit the deletion in core data
        NSError *error;
        if (![self.managedObjectContext save:&error])
            NSLog(@"Failed to delete question item with error: %@", [error domain]);
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
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
            NSLog(@"%@", newQuestion.question);
            break;
        }
    }
    
    BOOL ok = [[NSString stringWithFormat:@"{\"Question\": \"%@\", \"qImage\": \"%@\", \"Answer\": \"%@\", \"aImage\": \"%@\", \"qid\": \"%@\"}", [newQuestion.question stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"], newQuestion.qPictureName, [newQuestion.answer stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"], newQuestion.aPictureName, newQuestion.qid] writeToURL:docURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:groupID];
     containerURL = [containerURL URLByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/test.txt"]];
*/
    
    [self processJsonFile];
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self performSegueWithIdentifier: @"TextQuestion" sender: self];
    }
}

#pragma mark - Segue methods

//  When add is pressed or a table row is selected
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"AddQuestion"])
    {
        //  Get a reference to our detail view
           QuestionDetail *qd = (QuestionDetail *)[segue destinationViewController];
        
        //  Pass the managed object context to the destination view controller
        qd.managedObjectContext = managedObjectContext;
    }
    else if ([[segue identifier] isEqualToString:@"TextQuestion"])
    {
        if ([self.searchDisplayController isActive]) {
            TextQuestion *tq = (TextQuestion *)[segue destinationViewController];
            tq.managedObjectContext = managedObjectContext;
            Questions *currentCell = nil;
            
            NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            NSInteger selectedIndex = [indexPath row];
            
            currentCell = [filteredSearchArray objectAtIndex:selectedIndex];
            tq.currentQuestion = currentCell;
        }
        else {
            TextQuestion *tq = (TextQuestion *)[segue destinationViewController];
            tq.managedObjectContext = managedObjectContext;
            Questions *currentCell = nil;
            NSInteger selectedIndex = [[self.tableView indexPathForSelectedRow] row];
            currentCell = [questionListData objectAtIndex:selectedIndex];
            tq.currentQuestion = currentCell;
        }
    }
    else if ([[segue identifier] isEqualToString:@"LoggedAnswers"]){
        ViewLog *vl = (ViewLog *)[segue destinationViewController];
        
        vl.managedObjectContext = managedObjectContext;
    }
    else if ([[segue identifier] isEqualToString:@"NewQuestions"]){
        NewQuestionVC *nq = (NewQuestionVC *)[segue destinationViewController];
        
        nq.managedObjectContext = managedObjectContext;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Time" 
                                                    message:@"Answer question" 
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredSearchArray removeAllObjects];
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.question contains[c] %@ OR SELF.answer contains[c] %@",searchText, searchText];
    filteredSearchArray = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"question" andSortAscending:YES andContext:managedObjectContext];
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

@end