//
//  Questions.h
//  IMFull
//
//  Created by Andrew Amos on 11/08/12.
//  Copyright (c) 2012 University of Queensland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Questions : NSManagedObject

@property (nonatomic, retain) NSString * answer;
@property (nonatomic, retain) NSData * aPicture;
@property (nonatomic, retain) NSString * aSound;
@property (nonatomic, retain) NSNumber * correction;
@property (nonatomic, retain) NSNumber * current;
@property (nonatomic, retain) NSDate * datecreated;
@property (nonatomic, retain) NSDate * lastanswered;
@property (nonatomic, retain) NSDate * nextdue;
@property (nonatomic, retain) NSNumber * qid;
@property (nonatomic, retain) NSData * qPicture;
@property (nonatomic, retain) NSString * qSound;
@property (nonatomic, retain) NSString * question;
@property (nonatomic, retain) NSString * aPictureName;
@property (nonatomic, retain) NSString * qPictureName;

@end
