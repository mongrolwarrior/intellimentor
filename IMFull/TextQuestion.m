#import "TextQuestion.h"
#import "TextAnswer.h"
#import <AVFoundation/AVFoundation.h>

@implementation TextQuestion

@synthesize managedObjectContext;
@synthesize currentQuestion;
@synthesize qidField, questionField;
@synthesize qPictureField;
@synthesize soundButton;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    NSString *dbString = [currentQuestion question];
    dbString = [dbString stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    dbString = [dbString stringByReplacingOccurrencesOfString:@"<BR>" withString:@"\n"];
    [questionField setText:[dbString stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"]];
    
    if (currentQuestion.qPictureName) {
        NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:[currentQuestion qPictureName]];
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
        
        if (fileExists){
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,     NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:[currentQuestion qPictureName]];
            UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
            
            [qPictureField setImage:img];
            qPictureField.hidden = false;
        }
        else {
            NSURL *url;
            NSData *data;
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://www.insideandysbrain.com/images/", [currentQuestion qPictureName]]];
            
            data = [NSData dataWithContentsOfURL:url];
            [data writeToFile:storePath atomically:TRUE];
        }
    }
    else {
        qPictureField.hidden = true;
    }
    if (currentQuestion.qSound.length > 0) {
        soundButton.hidden = false;
    }
    else {
        soundButton.hidden = true;
    }
    if ([currentQuestion qPictureName])
    {
        
        
    }
}

#pragma mark - Segue methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //  Get a reference to our detail view
    //   QuestionDetail *qd = (QuestionDetail *)[segue destinationViewController];
    TextAnswer *ta = (TextAnswer *)[segue destinationViewController];
    
    //  Pass the managed object context to the destination view controller
    ta.managedObjectContext = managedObjectContext;
    
    //  Pass the picture object from the table that we want to view
    //        qd.currentQuestion = [questionListData objectAtIndex:selectedIndex];
    ta.currentQuestion = currentQuestion;
    //    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)playSound:(id)sender
{
    if ([currentQuestion qSound])
    {
        NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:[currentQuestion qSound]];
        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
        
        if (fileExists){
            NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",applicationDocumentsDir, [currentQuestion qSound]]];
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
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://www.insideandysbrain.com/Sounds/", [currentQuestion qSound]]];
            
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