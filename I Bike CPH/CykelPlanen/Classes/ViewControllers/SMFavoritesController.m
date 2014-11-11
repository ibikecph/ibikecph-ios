//
//  SMRegisterController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMFavoritesController.h"
#import "SMSearchController.h"
#import "DAKeyboardControl.h"
#import "SMUtil.h"
#import <CoreLocation/CoreLocation.h>
#import "SMFavoritesUtil.h"

typedef enum {
    favHome,
    favWork
} FavoriteType;
@interface SMFavoritesController () {
    FavoriteType searchFav;
}
@property (weak, nonatomic) IBOutlet UILabel *screenTitle;
@property (weak, nonatomic) IBOutlet UILabel *screenText;
@property (weak, nonatomic) IBOutlet SMPatternedButton *btnSave;
@property (weak, nonatomic) IBOutlet UIButton *btnSkip;

@property (nonatomic, strong) NSDictionary * homeDict;
@property (nonatomic, strong) NSDictionary * workDict;
@end

@implementation SMFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.workDict = nil;
    self.homeDict = nil;
    
    // Translation
    [self.screenTitle setText:translateString(@"favorites_title")];
    [self.screenText setText:translateString(@"favorites_text")];
    [self.btnSave setTitle:translateString(@"favorites_save_btn") forState:UIControlStateNormal];
    [self.btnSkip setTitle:translateString(@"btn_skip") forState:UIControlStateNormal];
    
    // Do not set default text for search fields in search controller
    //[favoriteHome setText:translateString(@"favorites_home_placeholder")];
    //[favoriteWork setText:translateString(@"favorites_work_placeholder")];
    
//    UIColor* lightGray = [UIColor colorWithRed:139.0/255.0 green:139.0/255.0 blue:139.0/255.0 alpha:139.0/255.0];
//    [favoriteHome setTextColor:lightGray];
//    [favoriteWork setTextColor:lightGray];
}

- (void)viewDidUnload {
    favoriteHome = nil;
    favoriteWork = nil;
    scrlView = nil;
    favoritesView = nil;
    [self setScreenTitle:nil];
    [self setScreenText:nil];
    [self setBtnSave:nil];
    [self setBtnSkip:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    if ([[SMFavoritesUtil getFavorites] count] > 0) {
        [self.view setAlpha:0.0f];
        [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
    } else {
        [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - button actions

- (IBAction)skipOver:(id)sender {
    // [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
    [self performSegueWithIdentifier:@"favoritesToFirstTimeIntro" sender:nil];
}

- (IBAction)saveFavorites:(id)sender {
    if (self.homeDict) {
        if ([self.homeDict objectForKey:@"subsource"] && [[self.homeDict objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : [self.homeDict objectForKey:@"name"],
             @"address" : [self.homeDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"home",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];
//            [SMFavoritesUtil saveToFavorites:@{
//             @"name" : [self.homeDict objectForKey:@"name"],
//             @"address" : [self.homeDict objectForKey:@"address"],
//             @"startDate" : [NSDate date],
//             @"endDate" : [NSDate date],
//             @"source" : @"favorites",
//             @"subsource" : @"home",
//             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.latitude],
//             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.longitude],
//             @"order" : @0
//             }];
        } else {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : translateString(@"Home"),
             @"address" : [self.homeDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"home",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];

//            [SMFavoritesUtil saveToFavorites:@{
//             @"name" : translateString(@"Home"),
//             @"address" : [self.homeDict objectForKey:@"address"],
//             @"startDate" : [NSDate date],
//             @"endDate" : [NSDate date],
//             @"source" : @"favorites",
//             @"subsource" : @"home",
//             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.latitude],
//             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.homeDict objectForKey:@"location"]).coordinate.longitude],
//             @"order" : @0
//             }];
        }
    }
    if (self.workDict) {
        if ([self.workDict objectForKey:@"subsource"] && [[self.workDict objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : [self.workDict objectForKey:@"name"],
             @"address" : [self.workDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"work",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];            
//            [SMFavoritesUtil saveToFavorites:@{
//             @"name" : [self.workDict objectForKey:@"name"],
//             @"address" : [self.workDict objectForKey:@"address"],
//             @"startDate" : [NSDate date],
//             @"endDate" : [NSDate date],
//             @"source" : @"favorites",
//             @"subsource" : @"work",
//             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.latitude],
//             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.longitude],
//             @"order" : @0
//             }];
        } else {
            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
            [fv addFavoriteToServer:@{
             @"name" : translateString(@"Work"),
             @"address" : [self.workDict objectForKey:@"address"],
             @"startDate" : [NSDate date],
             @"endDate" : [NSDate date],
             @"source" : @"favorites",
             @"subsource" : @"work",
             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.latitude],
             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.longitude],
             @"order" : @0
             }];
//            [SMFavoritesUtil saveToFavorites:@{
//             @"name" : translateString(@"Work"),
//             @"address" : [self.workDict objectForKey:@"address"],
//             @"startDate" : [NSDate date],
//             @"endDate" : [NSDate date],
//             @"source" : @"favorites",
//             @"subsource" : @"work",
//             @"lat" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.latitude],
//             @"long" : [NSNumber numberWithDouble:((CLLocation*)[self.workDict objectForKey:@"location"]).coordinate.longitude],
//             @"order" : @0
//             }];
        }
    }
    [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
}

- (IBAction)searchHome:(id)sender {
    searchFav = favHome;
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
}

- (IBAction)searchWork:(id)sender {
    searchFav = favWork;
    [self performSegueWithIdentifier:@"favToSearch" sender:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"favToSearch"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        [destViewController setShouldAllowCurrentPosition:NO];
        switch (searchFav) {
            case favHome:
                [destViewController setSearchText:favoriteHome.text];
                break;
            case favWork:
                [destViewController setSearchText:favoriteWork.text];
                break;
            default:
                break;
        }
        
    }
}

#pragma mark - search delegate

- (void)locationFound:(NSDictionary *)locationDict {
    switch (searchFav) {
        case favHome:
            [favoriteHome setText:[locationDict objectForKey:@"address"]];
            [self setHomeDict:locationDict];
            break;
        case favWork:
            [favoriteWork setText:[locationDict objectForKey:@"address"]];
            [self setWorkDict:locationDict];
            break;
        default:
            break;
    }
}

@end
