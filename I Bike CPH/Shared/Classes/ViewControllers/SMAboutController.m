//
//  SMAboutController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 31/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAboutController.h"

@interface SMAboutController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation SMAboutController

- (void)viewDidLoad {
    [super viewDidLoad];
//	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    [scrlView setContentSize:CGSizeMake(265.0f, 520.0f)];
    
    [self.textView setText:translateString(@"about_text")];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGSize size = [aboutText.text sizeWithFont:aboutText.font constrainedToSize:CGSizeMake(aboutText.frame.size.width, 100000.0f) lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = aboutText.frame;
    frame.size.height = size.height + 50.0f;
    aboutText.frame = frame;
}

#pragma mark - button actions

- (IBAction)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
