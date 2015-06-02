#import <UIKit/UIKit.h>
#import "Questions.h"
#import <AVFoundation/AVFoundation.h>

@interface QuestionDetail : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    AVAudioPlayer *audioPlayer;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) Questions *currentQuestion;
@property (strong, nonatomic) IBOutlet UITextView *pictureNameField;
@property (strong, nonatomic) IBOutlet UITextView *pictureAnswerName;
@property (strong, nonatomic) IBOutlet UITextView *questionField;
@property (strong, nonatomic) IBOutlet UITextView *answerField;
@property (strong, nonatomic) IBOutlet UIImageView *qpictureField;

@property (strong, nonatomic) UIImagePickerController *imagePicker;

@end