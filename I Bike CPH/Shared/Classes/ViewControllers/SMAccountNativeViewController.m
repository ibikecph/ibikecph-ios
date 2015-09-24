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


@interface SMAccountNativeViewController () <SMAPIRequestDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutButton;

@property (strong, nonatomic) NSString *password;

@property (nonatomic, strong) SMAPIRequest *apr;

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



#pragma mark - IBAction

- (IBAction)editAccount:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.ibikecph.dk/account"]];
}
 
- (IBAction)deleteAccount:(id)sender {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"delete_account_title".localized message:@"delete_account_text".localized preferredStyle:UIAlertControllerStyleAlert];
    // Password field
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.delegate = self;
        textField.secureTextEntry = true;
    }];
    // Cancel
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel".localized style:UIAlertActionStyleCancel handler:nil]];
    // Delete
    [controller addAction:[UIAlertAction actionWithTitle:@"Delete".localized style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteAccountConfirmedWithPassword:self.password];
    }]];
    [self presentViewController:controller animated:YES completion:nil];
}
 
- (void)deleteAccountConfirmedWithPassword:(NSString *)password {
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"deleteUser"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    NSMutableDictionary *request = [API_DELETE_USER_DATA mutableCopy];
    request[@"service"] = [NSString stringWithFormat:@"%@/%@", request[@"service"], self.appDelegate.appSettings[@"id"]];
    [self.apr executeRequest:request withParams:@{
                                                 @"user": @{ @"password" : password },
                                                 @"auth_token": self.appDelegate.appSettings[@"auth_token"]
                                                 }
     ];
}
 
- (IBAction)logout:(id)sender {
    [UserHelper logout];
    [self dismiss];
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
            self.nameLabel.text = result[@"data"][@"name"];
            self.emailLabel.text = result[@"data"][@"email"];
            NSURL *imageUrl = [NSURL URLWithString:result[@"data"][@"image_url"]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
            self.imageView.image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        } else if ([req.requestIdentifier isEqualToString:@"deleteUser"]) {
            if (![SMAnalytics trackEventWithCategory:@"Account" withAction:@"Delete" withLabel:@"" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
            debugLog(@"Account deleted!!!");
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"account_deleted".localized message:@"" delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            [UserHelper logout];
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


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.password = textField.text;
    return YES;
}


#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

