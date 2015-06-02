//
//  NewQuestionVC.h
//  IMFull
//
//  Created by Andrew Amos on 17/08/12.
//  Copyright (c) 2012 University of Queensland. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewQuestionVC : UITableViewController

@property (nonatomic, strong) NSMutableArray *noncurrentQuestions;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)readDataForTable;

@end
