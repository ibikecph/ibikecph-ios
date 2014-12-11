//
//  SMCyLwFirstTimeIntro.m
//  Supercykelstierne
//
//  Created by Rasko Gojkovic on 6/27/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import "SMCyLwFirstTimeIntro.h"

@interface SMCyLwFirstTimeIntro ()
@property (weak, nonatomic) IBOutlet UIButton *btnExitGuide;
@property (weak, nonatomic) IBOutlet UILabel *screenTitle;
@property (weak, nonatomic) IBOutlet UILabel *screenTopText;
@property (weak, nonatomic) IBOutlet UILabel *screenBottomText;

@end

@implementation SMCyLwFirstTimeIntro

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.screenTitle setText:translateString(@"break_route_title")];
    [self.screenTopText setText:translateString(@"break_route_text_top")];
    [self.screenBottomText setText:translateString(@"break_route_text_bottom")];
    [self.exitButton setTitle:translateString(@"break_route_exit") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onExit:(UIButton *)sender {
    [self performSegueWithIdentifier:@"firstTimeIntroToMap" sender:self];
}

@end
