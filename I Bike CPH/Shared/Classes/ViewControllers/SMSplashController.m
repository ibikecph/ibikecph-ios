//
//  SMSplashController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 17/03/2013.
//  Copyright (c) 2013. City of Copenhagen. All rights reserved.
//

#import "SMSplashController.h"

@interface SMSplashController ()
@end

@implementation SMSplashController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.appDelegate loadSettings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
        [self goToMain];
    }
}

- (void)goToMain {
    [self performSegueWithIdentifier:@"splashToMain" sender:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
