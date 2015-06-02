#import <UIKit/UIKit.h>
#import "Questions.h"
#import <AVFoundation/AVFoundation.h>

@interface TextQuestion : UITableViewController <UINavigationControllerDelegate>{
    AVAudioPlayer *audioPlayer;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) Questions *currentQuestion;
@property (strong, nonatomic) IBOutlet UILabel *qidField;
@property (strong, nonatomic) IBOutlet UITextView *questionField;
@property (strong, nonatomic) IBOutlet UIImageView *qPictureField;
@property (strong, nonatomic) IBOutlet UIButton *soundButton;

@end