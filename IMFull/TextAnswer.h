#import <UIKit/UIKit.h>
#import "Questions.h"
#import "AnswerLog.h"
#import <AVFoundation/AVFoundation.h>

@interface TextAnswer : UITableViewController <UINavigationControllerDelegate>{
    AVAudioPlayer *audioPlayer;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) Questions *currentQuestion;
@property (strong, nonatomic) AnswerLog *logAnswer;
@property (strong, nonatomic) IBOutlet UILabel *qidField;
@property (strong, nonatomic) IBOutlet UITextView *answerField;
@property (strong, nonatomic) IBOutlet UIImageView *aPictureField;
@property (strong, nonatomic) IBOutlet UIButton *soundButton;
@property (nonatomic, strong) NSMutableArray *noncurrentQuestions;

@end