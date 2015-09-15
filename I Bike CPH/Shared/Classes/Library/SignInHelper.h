//
//  SignInHelper.h
//  I Bike CPH
//
//  Created by Tobias Due Munk on 09/09/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SignInHelperCallback)(BOOL success, NSString *errorTitle, NSString *errorDescription);

@interface SignInHelper : NSObject

- (void)registerWithName:(NSString *)name email:(NSString *)email password:(NSString *)password image:(UIImage *)image view:(UIView *)view callback:(SignInHelperCallback)callback;
- (void)loginWithEmail:(NSString *)email password:(NSString *)password view:(UIView *)view callback:(SignInHelperCallback)callback;
- (void)loginWithFacebookForView:(UIView *)view callback:(SignInHelperCallback)callback;

@end
