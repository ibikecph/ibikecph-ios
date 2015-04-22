//
//  SMCyLwFirstTimeIntro.h
//  Supercykelstierne
//
//  Created by Rasko Gojkovic on 6/27/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

//#import "SMCyBaseVC.h" // FIXME: Clean outcommented code up

/**
 * View controller for onboarding explaining break route.
 */
@interface SMCyLwFirstTimeIntro : UIViewController //SMCyBaseVC
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

- (IBAction)onExit:(UIButton *)sender;
@end
