//
//  SMRegisterController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 11/05/2013.
//  Copyright (c) 2013. City of Copenhagen. All rights reserved.
//

#import "SMRegisterController.h"
#import "DAKeyboardControl.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SMUtil.h"
#import "SMAppDelegate.h"
#import "UIImage+Resize.h"

@interface SMRegisterController () <SMAPIRequestDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmField;

@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, strong) UIImage * profileImage;


@end

@implementation SMRegisterController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"create_account";
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.imageButton.layer.cornerRadius = 5;
    self.imageButton.layer.masksToBounds = YES;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {}];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view removeKeyboardControl];
}


#pragma mark - button actions

- (IBAction)doRegister:(id)sender {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.passwordConfirmField resignFirstResponder];
    [self.nameField resignFirstResponder];
    
    if([SMUtil validateRegistrationName:self.nameField.text Email:self.emailField.text Password:self.passwordField.text AndRepeatedPassword:self.passwordConfirmField.text] != RVR_REGISTRATION_DATA_VALID){
        return;
    }
    
    NSMutableDictionary * user = [NSMutableDictionary dictionaryWithDictionary:@{
                                  @"name": self.nameField.text,
                                  @"email": self.emailField.text,
                                  @"email_confirmation": self.emailField.text,
                                  @"password": self.passwordField.text,
                                  @"password_confirmation": self.passwordConfirmField.text,
                                  @"account_source" : ORG_NAME
                                  }];
    
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:@{
                                    @"user" : user
                                    }];
    
    if (self.profileImage) {
        [[params objectForKey:@"user"] setValue:@{
         @"file" : [UIImageJPEGRepresentation(self.profileImage, 1.0f) base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0],
         @"original_filename" : @"image.jpg",
         @"filename" : @"image.jpg"
         } forKey:@"image_path"];
    }
    
    if ([self.passwordField.text isEqualToString:@""] == NO) {
        [[params objectForKey:@"user"] setValue:self.passwordField.text forKey:@"password"];
        [[params objectForKey:@"user"] setValue:self.passwordField.text forKey:@"password_confirmation"];
    }
    
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"register"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_REGISTER withParams:params];
}

- (IBAction)selectImageSource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES){
        UIActionSheet * ac  = [[UIActionSheet alloc] initWithTitle:@"choose_image_source".localized delegate:self cancelButtonTitle:@"Cancel".localized destructiveButtonTitle:nil otherButtonTitles:@"image_source_camera".localized, @"image_source_library".localized, nil];
        [ac showInView:self.view];
    } else {
        [self takePictureFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)takePictureFromSource:(UIImagePickerControllerSourceType)src {
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:src] == YES){
        cameraUI.sourceType = src;
    }else{
        if (src == UIImagePickerControllerSourceTypeCamera) {
            cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        } else {
            cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
    }
    
    NSArray* tmpAlloc_NSArray = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    cameraUI.mediaTypes =  tmpAlloc_NSArray;
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = self;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:cameraUI animated:YES completion:nil];
    }
}


#pragma mark - api delegate

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
}

-(void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:[error description] delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"register"]) {
//            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"auth_token"] forKey:@"auth_token"];
//            [self.appDelegate.appSettings setValue:[[result objectForKey:@"data"] objectForKey:@"id"] forKey:@"id"];
//            [self.appDelegate.appSettings setValue:self.emailField.text forKey:@"username"];
//            [self.appDelegate.appSettings setValue:self.passwordField.text forKey:@"password"];
//            [self.appDelegate.appSettings setValue:@"regular" forKey:@"loginType"];
//            [self.appDelegate saveSettings];
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"" message:@"register_successful".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            [self.navigationController popToRootViewControllerAnimated:YES];
            if (![SMAnalytics trackEventWithCategory:@"Register" withAction:@"Completed" withLabel:self.emailField.text withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        }
    } else {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.nameField) {
        [self.emailField becomeFirstResponder];
    } else if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self.passwordConfirmField becomeFirstResponder];
    } else if (textField == self.passwordConfirmField) {
        [self doRegister:nil];
    }
    return YES;
}


#pragma mark - imagepicker delegate

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    self.profileImage = [[info objectForKey:UIImagePickerControllerOriginalImage] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    [self.imageButton setImage:self.profileImage forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self takePictureFromSource:UIImagePickerControllerSourceTypeCamera];
            break;
        case 1:
            [self takePictureFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
        default:
            break;
    }
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
