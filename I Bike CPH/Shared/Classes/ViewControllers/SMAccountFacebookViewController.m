//
//  SMAccountFacebookViewController.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 13/01/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

#import "SMAccountFacebookViewController.h"

@interface SMAccountFacebookViewController() <SMAPIRequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) SMAPIRequest *apr;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) NSDictionary *userData;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *logoutButton;

@end


@implementation SMAccountFacebookViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"account".localized;
    
    //rounded corners for images
    self.imageView.layer.cornerRadius = 5;
    self.imageView.layer.masksToBounds = YES;
    
    // Request profile data
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"getUserFB"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:@{@"service" : [NSString stringWithFormat:@"users/%@", self.appDelegate.appSettings[@"id"]], @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS} withParams:@{@"auth_token": self.appDelegate.appSettings[@"auth_token"]}];
    self.profileImage = nil;
    
    // Translate views in navigation bars
    [SMTranslation translateView:self.logoutButton];
}


#pragma mark - Setters and Getters

- (void)setProfileImage:(UIImage *)profileImage {
    if (profileImage != _profileImage) {
        _profileImage = profileImage;
        
        self.imageView.image = self.profileImage;
    }
}


#pragma mark - IBAction

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


#pragma mark - SMApiRequestDelegate

- (void)request:(SMAPIRequest *)req failedWithError:(NSError *)error {
    if (error.code > 0) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:[error description] delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
    }
}

- (void)request:(SMAPIRequest *)req completedWithResult:(NSDictionary *)result {
    if ([[result objectForKey:@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"getUserFB"]) {
            self.nameLabel.text = result[@"data"][@"name"];
            NSURL *imageUrl = [NSURL URLWithString:result[@"data"][@"image_url"]];
            NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
            self.profileImage = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
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
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:[result objectForKey:@"info"] delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
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


#pragma mark - alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101) {
        switch (buttonIndex) {
            case 1:
                [self deleteAccountConfirmed];
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
