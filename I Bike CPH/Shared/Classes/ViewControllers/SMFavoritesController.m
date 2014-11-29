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

@property (nonatomic, strong) HistoryItem *homeItem;
@property (nonatomic, strong) HistoryItem *workItem;
@end

@implementation SMFavoritesController

- (void)viewDidLoad {
    [super viewDidLoad];
    
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    self.workItem = nil;
    self.homeItem = nil;
    
    // Translation
    [self.screenTitle setText:translateString(@"favorites_title")];
    [self.screenText setText:translateString(@"favorites_text")];
    [self.btnSave setTitle:translateString(@"favorites_save_btn") forState:UIControlStateNormal];
    [self.btnSkip setTitle:translateString(@"btn_skip") forState:UIControlStateNormal];
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
    [self performSegueWithIdentifier:@"favoritesToMain" sender:nil];
    [self performSegueWithIdentifier:@"favoritesToFirstTimeIntro" sender:nil];
}

- (IBAction)saveFavorites:(id)sender {
    if (self.homeItem) {
        FavoriteItem *item = [[FavoriteItem alloc] initWithOther:self.homeItem];
        item.origin = FavoriteItemTypeHome;
        SMFavoritesUtil *fv = [SMFavoritesUtil instance];
        [fv addFavoriteToServer:item];
    }
    if (self.workItem) {
        FavoriteItem *item = [[FavoriteItem alloc] initWithOther:self.workItem];
        item.origin = FavoriteItemTypeWork;
        SMFavoritesUtil *fv = [SMFavoritesUtil instance];
        [fv addFavoriteToServer:item];
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

- (void)locationFound:(NSObject<SearchListItem> *)item {
    switch (searchFav) {
        case favHome:
            [favoriteHome setText:item.name];
            [self setHomeItem:[[HistoryItem alloc] initWithOther:item startDate:[NSDate date] endDate:[NSDate date]]];
            break;
        case favWork:
            [favoriteWork setText:item.name];
            [self setWorkItem:[[HistoryItem alloc] initWithOther:item startDate:[NSDate date] endDate:[NSDate date]]];
            break;
        default:
            break;
    }
}

#pragma mark - statusbar style

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
