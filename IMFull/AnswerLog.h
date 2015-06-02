//
//  AnswerLog.h
//  IMFull
//
//  Created by Andrew Amos on 11/08/12.
//  Copyright (c) 2012 University of Queensland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AnswerLog : NSManagedObject

@property (nonatomic, retain) NSNumber * accuracy;
@property (nonatomic, retain) NSDate * dateanswered;
@property (nonatomic, retain) NSNumber * qid;

@end
