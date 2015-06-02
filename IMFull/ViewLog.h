//
//  ViewLog.h
//  IMFull
//
//  Created by Andrew Amos on 9/08/12.
//  Copyright (c) 2012 University of Queensland. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewLog : UITableViewController

@property (nonatomic, strong) NSArray *questionLog;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
