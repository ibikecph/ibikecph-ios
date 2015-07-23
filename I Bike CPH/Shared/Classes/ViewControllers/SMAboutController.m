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
    
    self.title = ([Macro instance].isIBikeCph ? @"about_app_ibc" : @"about_app_cp").localized;
    self.textView.text = ([Macro instance].isIBikeCph ? @"about_text_ibc" : @"about_text_cp").localized;
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.textView.textContainerInset = UIEdgeInsetsMake(20, 10, 20, 10);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGPoint offset = CGPointMake(0, -self.textView.contentInset.top);
    [self.textView setContentOffset:offset];
}


#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
