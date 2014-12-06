//
//  SMFavoritesViewController.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 04/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#import "SMFavoritesViewController.h"

@interface SMFavoritesViewController ()

@end

@implementation SMFavoritesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (IBAction)saveFavorite:(id)sender {
    // TODO: Move to SMFavoritesViewController
    //    NSMutableArray * favs = [SMFavoritesUtil getFavorites];
    //    NSPredicate * pred = [NSPredicate predicateWithFormat:@"name == %@", addFavName.text];
    //    NSArray * arr = [favs filteredArrayUsingPredicate:pred];
    //    if (arr.count > 0) {
    //        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_duplicate_favorite_name") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    //        [av show];
    //        return;
    //    }
    //
    //    if (self.locItem && self.locItem.address.length && [addFavName.text isEqualToString:@""] == NO) {
    //        if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
    //            NSString * favType;
    //            switch (currentFav) {
    //                case typeFavorite:
    //                    favType = @"favorite";
    //                    break;
    //                case typeHome:
    //                    favType = @"home";
    //                    break;
    //                case typeWork:
    //                    favType = @"work";
    //                    break;
    //                case typeSchool:
    //                    favType = @"school";
    //                    break;
    //                default:
    //                    favType = @"favorite";
    //                    break;
    //            }
    //            SMFavoritesUtil * fv = [SMFavoritesUtil instance];
    //            FavoriteItem *item = [[FavoriteItem alloc] initWithName:addFavName.text address:self.locItem.address location:self.locItem.location startDate:[NSDate date] endDate:[NSDate date] origin:FavoriteItemTypeUnknown];
    //            [fv addFavoriteToServer:item];
    //
    //            [self addFavoriteHide:nil];
    //
    //
    //            if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"New" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, self.locItem.location.coordinate.latitude, self.locItem.location.coordinate.longitude] withValue:0]) {
    //                debugLog(@"error in trackEvent");
    //            }
    //        } else {
    //            UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    //            [av show];
    //        }
    //    }
}

- (IBAction)deleteFavorite:(id)sender {
    // TODO
    //    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
    //        SMFavoritesUtil * fv = [SMFavoritesUtil instance];
    //        FavoriteItem *item = self.favoritesList[self.locIndex];
    //        [fv deleteFavoriteFromServer:item];
    //        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"Delete" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, item.location.coordinate.latitude, item.location.coordinate.longitude] withValue:0]) {
    //            debugLog(@"error in trackEvent");
    //        }
    //        [self addFavoriteHide:nil];
    //    } else {
    //        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    //        [av show];
    //
    //    }
}

- (IBAction)editSaveFavorite:(id)sender {
    
    // TODO
    //    if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
    //        NSString * favType;
    //        switch (currentFav) {
    //            case typeFavorite:
    //                favType = @"favorite";
    //                break;
    //            case typeHome:
    //                favType = @"home";
    //                break;
    //            case typeWork:
    //                favType = @"work";
    //                break;
    //            case typeSchool:
    //                favType = @"school";
    //                break;
    //            default:
    //                favType = @"favorite";
    //                break;
    //        }
    //
    //        FavoriteItem *itemAtIndex = self.favoritesList[self.locIndex];
    //        FavoriteItem *item = [[FavoriteItem alloc] initWithOther:self.locItem];
    //        item.identifier = itemAtIndex.identifier;
    //        item.startDate = [NSDate date];
    //        item.endDate = [NSDate date];
    //        debugLog(@"%@", item);
    //
    //        SMFavoritesUtil * fv = [SMFavoritesUtil instance];
    //        [fv editFavorite:item];
    //        [self addFavoriteHide:nil];
    //        if (![SMAnalytics trackEventWithCategory:@"Favorites" withAction:@"Save" withLabel:[NSString stringWithFormat:@"%@ - (%f, %f)", addFavName.text, item.location.coordinate.latitude, item.location.coordinate.longitude] withValue:0]) {
    //            debugLog(@"error in trackEvent");
    //        }
    //    } else {
    //        UIAlertView * av = [[UIAlertView alloc] initWithTitle:translateString(@"Error") message:translateString(@"error_not_logged_in") delegate:nil cancelButtonTitle:translateString(@"OK") otherButtonTitles:nil];
    //        [av show];
    //
    //    }
}


- (IBAction)findAddress:(id)sender {
    // TODO
    //    [self.view hideKeyboard];
    //    self.favName = addFavAddress.text;
    //    [self performSegueWithIdentifier:@"mainToSearch" sender:nil];
}

- (IBAction)addSelectFavorite:(id)sender {
    // TODO
    //    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
    //        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"Schoole")] ||
    //        [addFavName.text isEqualToString:@""]) {
    //        [addFavName setText:translateString(@"Favorite")];
    //    }
    //
    //
    //    [addFavFavoriteButton setSelected:YES];
    //    [addFavHomeButton setSelected:NO];
    //    [addFavWorkButton setSelected:NO];
    //    [addFavSchoolButton setSelected:NO];
    //    currentFav = typeFavorite;
}

- (IBAction)addSelectHome:(id)sender {
    // TODO
    //    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
    //        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
    //        [addFavName.text isEqualToString:@""]) {
    //        [addFavName setText:translateString(@"Home")];
    //    }
    //    [addFavFavoriteButton setSelected:NO];
    //    [addFavHomeButton setSelected:YES];
    //    [addFavWorkButton setSelected:NO];
    //    [addFavSchoolButton setSelected:NO];
    //    currentFav = typeHome;
}

- (IBAction)addSelectWork:(id)sender {
    // TODO
    //    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
    //        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
    //        [addFavName.text isEqualToString:@""]) {
    //        [addFavName setText:translateString(@"Work")];
    //    }
    //    [addFavFavoriteButton setSelected:NO];
    //    [addFavHomeButton setSelected:NO];
    //    [addFavWorkButton setSelected:YES];
    //    [addFavSchoolButton setSelected:NO];
    //    currentFav = typeWork;
}

- (IBAction)addSelectSchool:(id)sender {
    // TODO
    //    if ([addFavName.text isEqualToString:translateString(@"Favorite")] || [addFavName.text isEqualToString:translateString(@"Home")] ||
    //        [addFavName.text isEqualToString:translateString(@"Work")] || [addFavName.text isEqualToString:translateString(@"School")] ||
    //        [addFavName.text isEqualToString:@""]) {
    //        [addFavName setText:translateString(@"School")];
    //    }
    //    [addFavFavoriteButton setSelected:NO];
    //    [addFavHomeButton setSelected:NO];
    //    [addFavWorkButton setSelected:NO];
    //    [addFavSchoolButton setSelected:YES];
    //    currentFav = typeSchool;
}

- (IBAction)startEdit:(id)sender {
    // TODO
    //    [self.favoritesTableView setEditing:YES];
    //    [self.favoritesTableView reloadData];
}



//#pragma mark - search delegate
//
//- (void)locationFound:(NSObject<SearchListItem> *)locationItem {
//    self.locItem = [[FavoriteItem alloc] initWithOther:locationItem];
//    addFavAddress.text = self.locItem.address;
//    if (self.locItem.type == SearchListItemTypeFoursquare) {
//        addFavName.text = self.locItem.address;
//    } else {
//        switch (currentFav) {
//            case typeFavorite:
//                [addFavName setText:translateString(@"Favorite")];
//                break;
//            case typeHome:
//                [addFavName setText:translateString(@"Home")];
//                break;
//            case typeWork:
//                [addFavName setText:translateString(@"Work")];
//                break;
//            case typeSchool:
//                [addFavName setText:translateString(@"School")];
//                break;
//            default:
//                [addFavName setText:translateString(@"Favorite")];
//                break;
//        }
//    }
//}
//
//#pragma mark - textfield delegate
//
//- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [textField resignFirstResponder];
//    return YES;
//}


//
//#pragma mark - smfavorites delegate
//
//- (void)favoritesOperationFinishedSuccessfully:(id)req withData:(id)data {
//    pinWorking = NO;
//}

@end
