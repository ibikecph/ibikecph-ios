//
//  SMLoginController.m
//  I Bike CPH
//
//  Created by Rasko Gojkovic on 5/9/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMLoginController.h"
#import "DAKeyboardControl.h"
#import "SignInHelper.h"

@interface SMLoginController()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *loginEmail;
@property (weak, nonatomic) IBOutlet UITextField *loginPassword;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) SMAPIRequest *apr;
@property (nonatomic, strong) SignInHelper *signInHelper;

@end

@implementation SMLoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"log_in".localized;
    self.signInHelper = [SignInHelper new];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


#pragma mark - button actions

- (IBAction)doLogin:(id)sender {
    [self.loginEmail resignFirstResponder];
    [self.loginPassword resignFirstResponder];
    if ([self.loginEmail.text isEqualToString:@""] || [self.loginPassword.text isEqualToString:@""]) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"login_error_fields".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
        return;
    }
    [self.signInHelper loginWithEmail:self.loginEmail.text password:self.loginPassword.text view:self.view callback:^(BOOL success, NSString *errorTitle, NSString *errorDescription) {
        if (success) {
            [self loginSucceeded];
            return;
        }
        [self loginFailedWithErrorTitle:errorTitle description:errorDescription];
    }];
}

- (IBAction)forgotPassword:(id)sender {

    NSURL *url = [NSURL URLWithString:@"http://www.ibikecph.dk/users/password/new"];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}


- (IBAction)loginWithFacebook:(id)sender {
    [self.signInHelper loginWithFacebookForView:self.view callback:^(BOOL success, NSString *errorTitle, NSString *errorDescription) {
        if (success) {
            [self loginSucceeded];
            return;
        }
        [self loginFailedWithErrorTitle:errorTitle description:errorDescription];
    }];
}

- (void)loginSucceeded {
    [self dismiss];
}

- (void)loginFailedWithErrorTitle:(NSString *)title description:(NSString *)description {
    UIAlertView * av = [[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
    [av show];
}


#pragma mark - textfield delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.loginEmail) {
        [self.loginPassword becomeFirstResponder];
    }
    if (textField == self.loginPassword) {
        [self doLogin:nil];
    }
    return YES;
}


#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
