//
//  SignInHelper.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/09/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

#import "SignInHelper.h"


@interface SignInHelper()<SMAPIRequestDelegate>

@property (nonatomic, strong) SMAPIRequest * apr;
@property (nonatomic, weak) UIView *view;
@property (nonatomic, copy) SignInHelperCallback callback;
@property (nonatomic, strong) NSString *email;

@end


@implementation SignInHelper

- (SMAppDelegate *)appDelegate {
    return (SMAppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)registerWithName:(NSString *)name email:(NSString *)email password:(NSString *)password image:(UIImage *)image view:(UIView *)view callback:(SignInHelperCallback)callback {
    self.view = view;
    self.email = email;
    self.callback = callback;
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"register"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    
    NSMutableDictionary * user = @{
                                   @"name": name,
                                   @"email": email,
                                   @"email_confirmation": email, // Duplicate for API
                                   @"password": password,
                                   @"password_confirmation": password, // Duplicate for API
                                   @"account_source" : ORG_NAME
                                   }.mutableCopy;
    if (image) {
        NSString *imageData = [UIImageJPEGRepresentation(image, 0.7f) base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
        user[@"image_path"] = @{ @"file" : imageData,
                                 @"original_filename" : @"image.jpg",
                                 @"filename" : @"image.jpg"
                                 };
    }
    [self.apr executeRequest:API_REGISTER withParams:@{ @"user" : user }];
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password view:(UIView *)view callback:(SignInHelperCallback)callback {
    self.view = view;
    self.email = email;
    self.callback = callback;
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"login"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"email": email, @"password": password}}];
}

- (void)loginWithFacebookToken:(NSString*)fbToken view:(UIView *)view callback:(SignInHelperCallback)callback {
    self.view = view;
    self.callback = callback;
    SMAPIRequest * ap = [[SMAPIRequest alloc] initWithDelegeate:self];
    [self setApr:ap];
    [self.apr setRequestIdentifier:@"loginFB"];
    [self.apr showTransparentWaitingIndicatorInView:self.view];
    [self.apr executeRequest:API_LOGIN withParams:@{@"user": @{ @"fb_token": fbToken, @"account_source" : ORG_NAME}}];
}


- (void)loginWithFacebookForView:(UIView *)view callback:(SignInHelperCallback)callback {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    FacebookHandler *faceboookHandler = [FacebookHandler new];
    [faceboookHandler request:^(NSString *identifier, NSString *email, NSString *token, NSError *error) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (error.code == faceboookHandler.errorAccessNotAllowed) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"fb_login_error_no_access".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            NSLog(@"Couldn't sign in to Facebook %@", error.localizedDescription);
            return;
        }
        if (error) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"fb_login_error".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            NSLog(@"Couldn't sign in to Facebook %@", error.localizedDescription);
            return;
        }
        self.email = email;
        [self loginWithFacebookToken:token view:view callback:callback];
    }];
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
    if ([result[@"success"] boolValue]) {
        if ([req.requestIdentifier isEqualToString:@"register"]) {
            // Don't store when registering
            self.callback(true, nil, nil);
            return;
        }
        NSString *authToken = result[@"data"][@"auth_token"];
        NSString *authTokenKey = @"auth_token";
        NSString *privacyToken = result[@"data"][@"signature"];
        NSString *privacyTokenKey = @"signature";
        NSString *idString = result[@"data"][@"id"];
        NSString *idKey = @"id";
        NSString *loginTypeKey = @"loginType";
        NSString *loginTypeFacebook = @"facebook";
        NSString *emailKey = @"email";
        
        if (privacyToken) {
            self.appDelegate.appSettings[privacyTokenKey] = privacyToken;
        }
        if (self.email) {
            self.appDelegate.appSettings[emailKey] = self.email;
        }
        self.appDelegate.appSettings[authTokenKey] = authToken;
        self.appDelegate.appSettings[idKey] = idString;
        if ([req.requestIdentifier isEqualToString:@"login"] ||
            [req.requestIdentifier isEqualToString:@"autoLogin"] ||
            [req.requestIdentifier isEqualToString:@"loginFB"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserLoggedIn" object:nil];
        } else if ([req.requestIdentifier isEqualToString:@"register"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserRegistered" object:nil];
        }
        NSObject *provider = result[@"data"][@"provider"];
        if (provider != [NSNull null] && [provider isKindOfClass:[NSString class]]) {
            BOOL isFacebookUser = [((NSString *)provider) isEqualToString:loginTypeFacebook];
            self.appDelegate.appSettings[loginTypeKey] = isFacebookUser ? @"FB" : @"regular";
        } else {
            self.appDelegate.appSettings[loginTypeKey] = @"regular";
        }
        
        [self.appDelegate saveSettings];
        self.callback(true, nil, nil);
        return;
    }
    NSString *errorTitle = result[@"info_title"];
    if (!errorTitle) {
        errorTitle = @"Error".localized;
    }
    self.callback(false, errorTitle, result[@"info"]);
}




@end
