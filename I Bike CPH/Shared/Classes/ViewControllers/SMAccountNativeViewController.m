//
//  SMAccountNativeViewController.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 12/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

#import "SMAccountNativeViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "DAKeyboardControl.h"
#import "UIImage+Resize.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SMFavoritesUtil.h"


@interface SMAccountNativeViewController () <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, SMAPIRequestDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutButton;

@property (nonatomic, strong) SMAPIRequest *apr;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) NSDictionary *userData;

@property (nonatomic, assign) BOOL hasChanged;

@end


@implementation SMAccountNativeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"account".localized;
    
    // Rounded corners for images
    self.imageView.layer.cornerRadius = 5;
    self.imageView.layer.masksToBounds = YES;
    
    // Request profile data
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"getUser"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:@{@"service" : [NSString stringWithFormat:@"users/%@", [self.appDelegate.appSettings objectForKey:@"id"]], @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS} withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
    self.profileImage = nil;
    
    self.nameField.delegate = self;
    self.passwordField.delegate = self;
    self.passwordConfirmField.delegate = self;
    
    // Translate views in navigation bars
    [SMTranslation translateView:self.logoutButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view removeKeyboardControl];
}


#pragma mark - Setters and Getters

- (void)setProfileImage:(UIImage *)profileImage {
    if (profileImage != _profileImage) {
        _profileImage = profileImage;
        
        self.imageView.image = self.profileImage;
    }
}


#pragma mark - IBAction
 
- (IBAction)saveChanges:(id)sender {
    if ([self.passwordField.text isEqualToString:self.passwordConfirmField.text] == NO) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"register_error_passwords".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSMutableDictionary * user = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                 @"name": self.nameField.text,
                                                                                 @"email": self.emailField.text
                                                                                 }];
    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                   @"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"],
                                                                                   @"id": [self.appDelegate.appSettings objectForKey:@"id"],
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
    [self.apr setRequestIdentifier:@"updateUser"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_CHANGE_USER_DATA withParams:params];
}
 
- (IBAction)changeImage:(id)sender {
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
    
    [self presentViewController:cameraUI animated:YES completion:nil];
}
 
- (IBAction)deleteAccount:(id)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"delete_account_title".localized message:@"delete_account_text".localized delegate:self cancelButtonTitle:@"Cancel".localized otherButtonTitles:@"Delete".localized, nil];
    av.tag = 101;
    [av show];
    
}
 
- (void)deleteAccountConfirmed {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"deleteUser"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    NSMutableDictionary * params = [API_DELETE_USER_DATA mutableCopy];
    [params setValue:[NSString stringWithFormat:@"%@/%@", [params objectForKey:@"service"], [self.appDelegate.appSettings objectForKey:@"id"]] forKey:@"service"];
    [self.apr executeRequest:params withParams:@{@"auth_token": [self.appDelegate.appSettings objectForKey:@"auth_token"]}];
}
 
- (IBAction)logout:(id)sender {
    [Settings sharedInstance].tracking.on = false; // Turn off tracking when logging out
    [self.appDelegate.appSettings removeObjectForKey:@"auth_token"];
    [self.appDelegate.appSettings removeObjectForKey:@"id"];
    [self.appDelegate.appSettings removeObjectForKey:@"username"];
    [self.appDelegate.appSettings removeObjectForKey:@"password"];
    [self.appDelegate saveSettings];
    [self dismiss];
}


#pragma mark - UITextViewDelegate

#define ACCEPTABLE_CHARECTERS @" ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_."

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:ACCEPTABLE_CHARECTERS] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}


#pragma mark - SMAPIRequestDelegate

- (void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:[error description] delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"getUser"]) {
            self.nameField.text = result[@"data"][@"name"];
            self.emailField.text = result[@"data"][@"email"];
            NSURL *imageUrl = [NSURL URLWithString:result[@"data"][@"image_url"]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
            self.profileImage = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
            self.userData = @{@"name" : self.nameField.text, @"email" : self.emailField.text, @"password" : @"", @"repeatPassword" : @"", @"image" : self.profileImage ?:[UIImage new]};
        } else if ([req.requestIdentifier isEqualToString:@"updateUser"]) {
            debugLog(@"User updated!!!");
            self.hasChanged = NO;
            self.userData = @{@"name" : self.nameField.text, @"email" : self.emailField.text, @"password" : @"", @"repeatPassword" : @"", @"image" : self.profileImage ?:[UIImage new]};
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Data" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            self.profileImage = nil;
        } else if ([req.requestIdentifier isEqualToString:@"changePassword"]) {
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Save" withLabel:@"Password" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Password changed!!!");
        } else if ([req.requestIdentifier isEqualToString:@"deleteUser"]) {
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Delete" withLabel:@"" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Account deleted!!!");
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"account_deleted".localized message:@"" delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            [self.appDelegate.appSettings removeObjectForKey:@"auth_token"];
            [self.appDelegate.appSettings removeObjectForKey:@"id"];
            [self.appDelegate.appSettings removeObjectForKey:@"username"];
            [self.appDelegate.appSettings removeObjectForKey:@"password"];
            [self.appDelegate saveSettings];
            
            [self dismiss];
        } else {
            // Regular account type
            [SMFavoritesUtil saveFavorites:@[]];
            [self dismiss];
            return;
        }
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}

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


#pragma mark - UIImagePickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.profileImage = [info[UIImagePickerControllerOriginalImage] resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(560.0f, 560.0f) interpolationQuality:kCGInterpolationHigh];
    self.hasChanged = YES;
    [picker dismiss];
}


#pragma mark - UIActionSheetDelegate

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


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101) {
        switch (buttonIndex) {
            case 1:
                [self deleteAccountConfirmed];
                break;
                
            default:
                break;
        }
    } else if (alertView.tag == 100) {
        switch (buttonIndex) {
            case 1:
                [self dismiss];
                break;
                
            default:
                break;
        }
    }
}


#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

