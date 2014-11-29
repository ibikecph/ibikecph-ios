//
//  SMCyReminderVC.m
//  Cykelsuperstierne
//
//  Created by Rasko on 6/26/13.
//  Copyright (c) 2013 Rasko Gojkovic. All rights reserved.
//

#import "SMCyLwReminderVC.h"
#import "SMReminder.h"
//#import "SMCySettings.h"

@interface SMCyLwReminderVC ()
@property (weak, nonatomic) IBOutlet UILabel *screenTitle;
@property (weak, nonatomic) IBOutlet UILabel *screenText;
@property (weak, nonatomic) IBOutlet SMPatternedButton *btnSave;
@property (weak, nonatomic) IBOutlet UIButton *btnSkip;

@property (weak, nonatomic) IBOutlet UILabel *monday;
@property (weak, nonatomic) IBOutlet UILabel *tuesday;
@property (weak, nonatomic) IBOutlet UILabel *wednesday;
@property (weak, nonatomic) IBOutlet UILabel *thursday;
@property (weak, nonatomic) IBOutlet UILabel *friday;

@end

@implementation SMCyLwReminderVC

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
    [self.screenTitle setText:translateString(@"reminder_title")];
    [self.screenText setText:translateString(@"reminder_text")];
    [self.btnSave setTitle:translateString(@"reminder_save_btn") forState:UIControlStateNormal];
    [self.btnSkip setTitle:translateString(@"btn_skip") forState:UIControlStateNormal];
    
    // Translate days of the week
    [self.monday setText:translateString(@"monday")];
    [self.tuesday setText:translateString(@"tuesday")];
    [self.wednesday setText:translateString(@"wednesday")];
    [self.thursday setText:translateString(@"thursday")];
    [self.friday setText:translateString(@"friday")];
    
    // Set tint color for switches
    UIColor* orange = [UIColor colorWithRed:232.0f/255.0f green:123.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    [self.swMonday setOnTintColor:orange];
    [self.swTuesday setOnTintColor:orange];
    [self.swWednesday setOnTintColor:orange];
    [self.swThursday setOnTintColor:orange];
    [self.swFriday setOnTintColor:orange];
    
    [[SMReminder sharedInstance] save];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveReminder:(UIButton *)sender {
    SMReminder * reminder = [SMReminder sharedInstance];

    [reminder setReminder:self.swMonday.isOn forDay:DayMonday save:NO];
    [reminder setReminder:self.swTuesday.isOn forDay:DayTuesday save:NO];
    [reminder setReminder:self.swWednesday.isOn forDay:DayWednesday save:NO];
    [reminder setReminder:self.swThursday.isOn forDay:DayThursday save:NO];
    [reminder setReminder:self.swFriday.isOn forDay:DayFriday save:NO];
    
    [reminder save];
    
    [self goToNextView];
}

- (IBAction)skip:(UIButton *)sender {
    [self goToNextView];
}

- (void) goToNextView{
    [self performSegueWithIdentifier:@"goToFavorites" sender:self];
}

@end
