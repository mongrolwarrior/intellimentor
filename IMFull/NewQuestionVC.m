//
//  NewQuestionVC.m
//  IMFull
//
//  Created by Andrew Amos on 17/08/12.
//  Copyright (c) 2012 University of Queensland. All rights reserved.
//

#import "NewQuestionVC.h"
#import "Questions.h"
#import "CoreDataHelper.h"

@interface NewQuestionVC ()

@end

@implementation NewQuestionVC

@synthesize noncurrentQuestions;
@synthesize managedObjectContext;

//  When the view reappears, read new data for table
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //  Repopulate the array with new table data
    [self readDataForTable];
}

//  Grab data for table - this will be used whenever the list appears or reappears after an add/edit
- (void)readDataForTable
{
    //  Grab the data
    //   NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-20000];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"current == NO"];
    noncurrentQuestions = [CoreDataHelper searchObjectsForEntity:@"Questions" withPredicate:predicate andSortKey:@"qid" andSortAscending:NO andContext:managedObjectContext];
    //   questionListData = [CoreDataHelper getObjectsForEntity:@"Questions" withSortKey:@"nextdue" andSortAscending:YES andContext:managedObjectContext];
    
    //  Force table refresh
    [self.tableView reloadData];
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
    return [noncurrentQuestions count];
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
    Questions *currentCell = [noncurrentQuestions objectAtIndex:indexPath.row];
    
    //  Fill in the cell contents
    cell.textLabel.text = [currentCell.qid stringValue];
    cell.detailTextLabel.text = [currentCell question];
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectedIndex = [[self.tableView indexPathForSelectedRow] row];
    
    Questions *activateQuestion = [noncurrentQuestions objectAtIndex:selectedIndex];
    
    activateQuestion.current = [NSNumber numberWithBool:true];
    activateQuestion.lastanswered = [NSDate dateWithTimeIntervalSinceNow:-300];
    activateQuestion.nextdue = [NSDate date];
    
    NSError *error;
    
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to save nextdue with error: %@", [error domain]);
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger intVal = [prefs integerForKey:@"timeLag"];
    intVal = intVal + 2;
    [prefs setInteger:intVal forKey:@"timeLag"];
    
    // Manage date of most recent initiated question and count of questions today
    if ([[NSDateFormatter localizedStringFromDate:[prefs objectForKey:@"lastNewQuestion"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle]])
        // If the most recent new question was initiated on the same date as today add one to the count
    {
        [prefs setInteger:[prefs integerForKey:@"countNewQuestions"]+1 forKey:@"countNewQuestions"];
    }   // Else reset date and count
    else
    {
        [prefs setInteger:1 forKey:@"countNewQuestions"];
        [prefs setObject:[NSDate date] forKey:@"lastNewQuestion"];
    }
    [prefs synchronize];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
