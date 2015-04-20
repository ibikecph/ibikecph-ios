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
    
    self.title = ([Macro isIBikeCph] ? @"about_app_ibc" : @"about_app_cp").localized;
    self.textView.text = ([Macro isIBikeCph] ? @"about_text_ibc" : @"about_text_cp").localized;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
