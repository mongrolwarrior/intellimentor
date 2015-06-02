#import "QuestionDetail.h"
#import <AVFoundation/AVFoundation.h>

@implementation QuestionDetail

@synthesize managedObjectContext;
@synthesize currentQuestion;
@synthesize pictureNameField, questionField, answerField;
@synthesize pictureAnswerName;
@synthesize qpictureField;
@synthesize imagePicker;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // If we are editing an existing picture, then put the details from Core Data into the text fields for displaying
    if (currentQuestion)
    {
        [questionField setText:[currentQuestion question]];
        [answerField setText:[currentQuestion answer]];
     /*   if ([currentQuestion qPictureName])
        {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:[currentQuestion qPictureName]];
            UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
            [qpictureField setImage:img];
        }*/
        if (currentQuestion.qPictureName) {
            NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:[currentQuestion qPictureName]];
            
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
            
            if (fileExists){
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,     NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:[currentQuestion qPictureName]];
                UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
                
                [qpictureField setImage:img];
                qpictureField.hidden = false;
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
            qpictureField.hidden = true;
        }
    }
}

#pragma mark - Button actions

- (IBAction)editSaveButtonPressed:(id)sender
{
    // If we are adding a new picture (because we didnt pass one from the table) then create an entry
    if (!currentQuestion)
    {
        self.currentQuestion = (Questions *)[NSEntityDescription insertNewObjectForEntityForName:@"Questions" inManagedObjectContext:self.managedObjectContext];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSInteger intVal = [prefs integerForKey:@"idCount"];
        intVal = intVal + 1;
        [prefs setInteger:intVal forKey:@"idCount"];
        [prefs synchronize];
        NSNumber *qidNumber = [NSNumber numberWithInt: intVal];
        [self.currentQuestion setQid:qidNumber];
        [self.currentQuestion setCurrent:[NSNumber numberWithInt:0]];
    }
    // For both new and existing Questions, fill in the details from the form
    if (pictureNameField) {
        [self.currentQuestion setQPictureName:[pictureNameField text]];
    }
    if (pictureAnswerName) {
        [self.currentQuestion setAPictureName:[pictureAnswerName text]];
    }
    [self.currentQuestion setQuestion:[questionField text]];
    [self.currentQuestion setAnswer:[answerField text]];
    [self.currentQuestion setDatecreated:[NSDate date]];
    
    //  Commit item to core data
    NSError *error;
    if (![self.managedObjectContext save:&error])
        NSLog(@"Failed to add new picture with error: %@", [error domain]);
    
    //  Automatically pop to previous view now we're done adding
    [self.navigationController popViewControllerAnimated:YES];
}

//  Pick an image from album
- (IBAction)imageFromAlbum:(id)sender
{
    // NEW USE - make question current with due date 5 minutes ago
    self.currentQuestion.current = [NSNumber numberWithBool:true];
    self.currentQuestion.lastanswered = [NSDate dateWithTimeIntervalSinceNow:-300];
    self.currentQuestion.nextdue = [NSDate date];
    /*      OLD USE - PICK IMAGE FROM ALBUM - DOESN'T SAVE IMAGE
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:imagePicker animated:YES completion:nil]; */
}

//  Take an image with camera
- (IBAction)imageFromCamera:(id)sender
{
    // ACTUALLY IMAGE FROM LIBRARY
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:imagePicker animated:YES completion:nil];
  /*  
    ACTUALLY IMAGE FROM CAMERA
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    [self presentViewController:imagePicker animated:YES completion:nil];*/
}

//  Resign the keyboard after Done is pressed when editing text fields
- (IBAction)resignKeyboard:(id)sender
{
    [sender resignFirstResponder];
}

#pragma mark - Image Picker Delegate Methods

//  Dismiss the image picker on selection and use the resulting image in our ImageView
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [imagePicker dismissModalViewControllerAnimated:YES];
    
    NSData *pngData = UIImagePNGRepresentation(image);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    NSString *filePath;
    if ([pictureNameField.text length]>0) {
        filePath = [documentsPath stringByAppendingPathComponent:[pictureNameField text]]; //Add the file name
    }
    else
    {
        filePath = [documentsPath stringByAppendingPathComponent:[pictureAnswerName text]]; //Add the file name
    }
    
    [pngData writeToFile:filePath atomically:YES]; //Write the file
    
    [qpictureField setImage:image];
}

//  On cancel, only dismiss the picker controller
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [imagePicker dismissViewControllerAnimated:YES completion:nil];
    // old deprecated form [imagePicker dismissModalViewControllerAnimated:YES];
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
    else {
        [self.currentQuestion setQSound:@"5.mp3"];
        NSError *error;
        if (![self.managedObjectContext save:&error])
            NSLog(@"Failed to add new sound with error: %@", [error domain]);
    }
    
    
}



@end