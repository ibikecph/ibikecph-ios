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
#import "TTTAttributedLabel.h"
#import "SignInHelper.h"

@interface SMRegisterController () <UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    TTTAttributedLabelDelegate>


@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmField;
@property (weak, nonatomic) IBOutlet UISwitch *termSwitch;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *termsLabel;

@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, strong) UIImage * profileImage;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) SignInHelper *signInHelper;


@end

@implementation SMRegisterController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"create_account".localized;
    self.signInHelper = [SignInHelper new];
    
    // Terms
    NSString *urlString = @"accept_user_terms_link".localized;
    NSURL *url = [NSURL URLWithString:urlString];
    self.termsLabel.delegate = self;
    self.termsLabel.linkAttributes = @{ NSForegroundColorAttributeName : self.termsLabel.textColor, NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle) };
    [SMTranslation translateView:self.termsLabel];
    NSRange range = [self.termsLabel.text rangeOfString:@"accept_user_terms_link_highlight".localized];
    [self.termsLabel addLinkToURL:url withRange:range]; // Embedding a custom link in a substring
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.imageButton.layer.cornerRadius = 5;
    self.imageButton.layer.masksToBounds = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        CGFloat keyboardIsVisibleWithHeight = CGRectGetHeight(weakSelf.view.frame) - CGRectGetMinY(keyboardFrameInView);
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, keyboardIsVisibleWithHeight, 0);
        weakSelf.scrollView.contentInset = insets;
        weakSelf.scrollView.scrollIndicatorInsets = insets;
    }];
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
    
    if([SMUtil validateRegistrationName:self.nameField.text Email:self.emailField.text Password:self.passwordField.text AndRepeatedPassword:self.passwordConfirmField.text userTerms:self.termSwitch.on] != RVR_REGISTRATION_DATA_VALID){
        return;
    }
    
    [self.signInHelper registerWithName:self.nameField.text email:self.emailField.text password:self.passwordField.text image:self.profileImage view:self.view callback:^(BOOL success, NSString *errorTitle, NSString *errorDescription) {
        if (success) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"" message:@"register_successful".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            [self.navigationController popToRootViewControllerAnimated:YES];

            return;
        }
        [self loginFailedWithErrorTitle:errorTitle description:errorDescription];
    }];
}

- (IBAction)loginWithFacebook:(id)sender {
    [self.signInHelper loginWithFacebookForView:self.view callback:^(BOOL success, NSString *errorTitle, NSString *errorDescription) {
        if (success) {
            [self.navigationController popToRootViewControllerAnimated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserLoggedIn" object:nil];
            return;
        }
        [self loginFailedWithErrorTitle:errorTitle description:errorDescription];
    }];
}

- (void)loginFailedWithErrorTitle:(NSString *)title description:(NSString *)description {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
    [av show];
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


#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
