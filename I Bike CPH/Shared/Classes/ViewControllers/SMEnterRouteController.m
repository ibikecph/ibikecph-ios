//
//  SMEnterRouteController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 13/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMEnterRouteController.h"
#import "SMAppDelegate.h"
#import "SMUtil.h"
#import "SMLocationManager.h"
#import "SMEnterRouteCell.h"
#import "SMAutocompleteHeader.h"
#import "SMViewMoreCell.h"
#import "SMFavoritesUtil.h"
#import "SMSearchHistory.h"

typedef enum {
    fieldTo,
    fieldFrom
} CurrentField;

@interface SMEnterRouteController () {
    CurrentField delegateField;
    BOOL favoritesOpen;
    BOOL historyOpen;
}
@property (nonatomic, strong) NSArray * groupedList;
@property (nonatomic, strong) NSObject<SearchListItem> *fromItem;
@property (nonatomic, strong) NSObject<SearchListItem> *toItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButton;
@property (weak, nonatomic) IBOutlet UIButton *swapButton;
@property (weak, nonatomic) IBOutlet UIButton *fromButton;
@property (weak, nonatomic) IBOutlet UIButton *toButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *loaderView;

@end

@implementation SMEnterRouteController

#define MAX_FAVORITES 3
#define MAX_HISTORY 10

- (void)viewDidLoad {
    [super viewDidLoad];
    
    favoritesOpen = NO;
    historyOpen = NO;
    
	[self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    self.fromItem = [CurrentLocationItem new];

    self.toItem = nil;

    
    // TODO: Verify that this can be deleted
//    for (id v in self.tableView.subviews) {
//        if ([v isKindOfClass:[UIScrollView class]]) {
//            [v setDelegate:self];
//        }
//    }
    
    
    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
    NSMutableArray * saved = [SMFavoritesUtil getFavorites];
    /**
     * add saved routes here
     */
    
    
    /**
     * add latest 10 searches
     */
    NSMutableArray * last = [NSMutableArray array];
    for (int i = 0; i < MIN(10, [appd.searchHistory count]); i++) {
        BOOL found = NO;
        NSObject<SearchListItem> *item = [appd.searchHistory objectAtIndex:i];
        for (NSObject<SearchListItem> *item1 in last) {
            if ([item1.address isEqualToString:item.address]) {
                found = YES;
                break;
            }
        }
        if (found == NO) {
            [last addObject:item];
        }
    }
    
    [self setGroupedList:@[saved, last]];
    [self.tableView reloadData];

    if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Search" withLabel:@"" withValue:0]) {
        debugLog(@"error in trackEvent");
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Setters and Getters

- (void)setFromItem:(NSObject<SearchListItem> *)fromItem {
    if (fromItem != _fromItem) {
        _fromItem = fromItem;
        
        NSString *title;
        if (self.fromItem) {
            title = [self textFromItem:self.fromItem];
        } else {
            title = @"search_to_placeholder";
        }
        [self.fromButton setTitle:title forState:UIControlStateNormal];
        
        [self checkSwapButtonState];
        [self checkStartButtonState];
    }
}

- (void)setToItem:(NSObject<SearchListItem> *)toItem {
    if (toItem != _toItem) {
        _toItem = toItem;
        
        NSString *title;
        if (self.toItem) {
            title = [self textFromItem:self.toItem];
        } else {
            title = @"search_to_placeholder".localized;
        }
        [self.toButton setTitle:title forState:UIControlStateNormal];
        
        [self checkSwapButtonState];
        [self checkStartButtonState];
    }
}


#pragma mark - 

- (void)checkSwapButtonState {
    BOOL isCurrentType = self.fromItem.type == SearchListItemTypeCurrentLocation;
    self.swapButton.enabled = !isCurrentType;
}

- (void)checkStartButtonState {
    BOOL hasEndPoints = self.toItem && self.fromItem;
    self.startButton.enabled = hasEndPoints;
}


#pragma mark - button actions

- (IBAction)swapFields:(id)sender {
    if (self.fromItem == nil || self.fromItem.type == SearchListItemTypeCurrentLocation) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"Error".localized message:@"current_position_cant_be_destination".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSObject<SearchListItem> *item = self.fromItem;
    self.fromItem = self.toItem;
    self.toItem = item;
}

- (IBAction)findRoute:(id)sender {
    if (!self.toItem || !self.fromItem) {
        return;
    }
    
    if (self.toItem.type == SearchListItemTypeCurrentLocation) {
        UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:@"error_invalid_to_address".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
        [av show];
        return;
    }
    
    if (self.fromItem == nil) {
        if ([SMLocationManager instance].hasValidLocation == NO) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:@"error_no_gps_location".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            return;            
        } else {
            self.fromItem = [CurrentLocationItem new];
        }
    }
    
    if ([self.fromItem.name isEqualToString:CURRENT_POSITION_STRING] == NO) {
        if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"From" withLabel:self.fromItem.name withValue:0]) {
            debugLog(@"error in trackEvent");
        }
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        [self.loaderView setAlpha:1.0f];
    }];
    
    CLLocation * s = self.fromItem.location;
    CLLocation * e = self.toItem.location;
    
    NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", self.fromButton.titleLabel.text, s.coordinate.latitude, s.coordinate.longitude, self.toButton.titleLabel.text, e.coordinate.latitude, e.coordinate.longitude];
    debugLog(@"%@", st);
    if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Finder" withLabel:st withValue:0]) {
        debugLog(@"error in trackPageview");
    }
    SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
    [r setAuxParam:@"startRoute"];
    [r getRouteFrom:s.coordinate to:e.coordinate via:nil];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"searchSegue"]) {
        SMSearchController *destViewController = segue.destinationViewController;
        [destViewController setDelegate:self];
        switch (delegateField) {
            case fieldFrom:
                destViewController.shouldAllowCurrentPosition = YES;
                destViewController.locationItem = self.fromItem;
                break;
            case fieldTo:
                destViewController.shouldAllowCurrentPosition = NO;
                destViewController.locationItem = self.toItem;
                break;
            default:
                break;
        }
       
    }
}

#pragma mark - osrm request delegate

- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
    [UIView animateWithDuration:0.2f animations:^{
        [self.loaderView setAlpha:0.0f];
    }];
}

- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
    if ([req.auxParam isEqualToString:@"nearestPoint"]) {
        CLLocation * s = res[@"start"];
        CLLocation * e = res[@"end"];
        
        NSString * st = [NSString stringWithFormat:@"Start: %@ (%f,%f) End: %@ (%f,%f)", self.fromButton.titleLabel.text, s.coordinate.latitude, s.coordinate.longitude, self.toButton.titleLabel.text, e.coordinate.latitude, e.coordinate.longitude];
        debugLog(@"%@", st);
        if (![SMAnalytics trackEventWithCategory:@"Route:" withAction:@"Finder" withLabel:st withValue:0]) {
            debugLog(@"error in trackPageview");
        }
        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
        [r setAuxParam:@"startRoute"];
        [r getRouteFrom:s.coordinate to:e.coordinate via:nil];
    } else if ([req.auxParam isEqualToString:@"startRoute"]){
        id jsonRoot = [NSJSONSerialization JSONObjectWithData:req.responseData options:NSJSONReadingAllowFragments error:nil];
        if (!jsonRoot || ([jsonRoot isKindOfClass:[NSDictionary class]] == NO) || ([jsonRoot[@"status"] intValue] != 0)) {
            UIAlertView * av = [[UIAlertView alloc] initWithTitle:nil message:@"error_route_not_found".localized delegate:nil cancelButtonTitle:@"OK".localized otherButtonTitles:nil];
            [av show];
            
        } else {
            HistoryItem *item = [[HistoryItem alloc] initWithOther:self.toItem startDate:[NSDate date] endDate:[NSDate date]];
            [SMSearchHistory saveToSearchHistory:item];
            
            if ([self.appDelegate.appSettings objectForKey:@"auth_token"]) {
                SMSearchHistory * sh = [SMSearchHistory instance];
                [sh setDelegate:self.appDelegate];
                [sh addSearchToServer:item];
            }
            
            [self dismiss];
            [self.delegate findRouteFrom:self.fromItem.location.coordinate to:self.toItem.location.coordinate fromAddress:self.fromButton.titleLabel.text toAddress:self.toButton.titleLabel.text withJSON:jsonRoot];
        }
        [UIView animateWithDuration:0.2f animations:^{
            [self.loaderView setAlpha:0.0f];
        }];
    } else {
        [UIView animateWithDuration:0.2f animations:^{
            [self.loaderView setAlpha:0.0f];
        }];
    }
}

- (void)serverNotReachable {
    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
    CGRect frame = v.frame;
    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
    [v setFrame: frame];
    [v setAlpha:0.0f];
    [self.view addSubview:v];
    [UIView animateWithDuration:ERROR_FADE animations:^{
        v.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            v.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [v removeFromSuperview];
        }];
    }];
}

#pragma mark - tap gesture

- (IBAction)toTapped:(id)sender {
    delegateField = fieldTo;
    [self performSegueWithIdentifier:@"searchSegue" sender:nil];
}

- (IBAction)fromTapped:(id)sender {
    delegateField = fieldFrom;
    [self performSegueWithIdentifier:@"searchSegue" sender:nil];
}


#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.groupedList count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [[self.groupedList objectAtIndex:section] count];
    if (section == 0) {
        if (count > MAX_FAVORITES) {
            if (favoritesOpen) {
                return count + 1;
            } else {
                return MAX_FAVORITES + 1;
            }
        } else {
            return count;
        }
    } else if (section == 1) {
        if (count > MAX_HISTORY) {
            if (historyOpen) {
                return count + 1;
            } else {
                return MAX_HISTORY + 1;
            }
        } else {
            return count;
        }        
    }
    return count;
}

- (BOOL)isCountButton:(NSIndexPath*)indexPath {
    NSInteger count = [[self.groupedList objectAtIndex:indexPath.section] count];
    if (indexPath.section == 0) {
        if (count > MAX_FAVORITES) {
            if (favoritesOpen) {
                if (indexPath.row == count) {
                    return YES;
                }
            } else {
                if (indexPath.row == MAX_FAVORITES) {
                    return YES;
                }
            }
        }
    } else if (indexPath.section == 1) {
        if (count > MAX_HISTORY) {
            if (historyOpen) {
                if (indexPath.row == count) {
                    return YES;
                }
            } else {
                if (indexPath.row == MAX_HISTORY) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self isCountButton:indexPath]) {
        SMViewMoreCell * cell = [tableView dequeueReusableCellWithIdentifier:@"viewMoreCell"];
        if (indexPath.section == 0) {
            if (favoritesOpen) {
                [cell.buttonLabel setText:@"show_less".localized];
            } else {
                [cell.buttonLabel setText:@"show_more".localized];
            }
        } else {
            if (historyOpen) {
                [cell.buttonLabel setText:@"show_less".localized];
            } else {
                [cell.buttonLabel setText:@"show_more".localized];
            }            
        }
        return cell;
    } else {
        NSString * identifier = @"autocompleteCell";

        NSObject<SearchListItem> *currentRow = [[self.groupedList objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        SMEnterRouteCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        cell.nameLabel.text = currentRow.name;
        
        // TODO: Use logic from SMSearchCell
//        if ([[currentRow objectForKey:@"source"] isEqualToString:@"fb"]) {
//            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
//            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteCalendar"]];
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"ios"]) {
//            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteCalendar"]];
//            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteCalendar"]];
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"contacts"]) {
//            [cell.iconImage setImage:[UIImage imageNamed:@"findRouteContacts"]];
//            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findRouteContacts"]];
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"]) {
//            if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"foursquare"]) {
//                [cell.iconImage setImage:[UIImage imageNamed:@"findLocation"]];
//                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findLocation"]];
//            } else {
//                [cell.iconImage setImage:[UIImage imageNamed:@"findAutocomplete"]];
//                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findAutocomplete"]];
//            }
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"searchHistory"]) {
//            [cell.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
//            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favorites"]) {
//            if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"home"]) {
//                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favHomeWhite"]];
//                [cell.iconImage setImage:[UIImage imageNamed:@"favHomeGrey"]];
//            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"work"]) {
//                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favWorkWhite"]];
//                [cell.iconImage setImage:[UIImage imageNamed:@"favWorkGrey"]];
//            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"school"]) {
//                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favSchoolWhite"]];
//                [cell.iconImage setImage:[UIImage imageNamed:@"favSchoolGrey"]];
//            } else if ([[currentRow objectForKey:@"subsource"] isEqualToString:@"favorite"]) {
//                [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"favStarWhiteSmall"]];
//                [cell.iconImage setImage:[UIImage imageNamed:@"favStarGreySmall"]];
//            } else {
//                [cell.iconImage setImage:nil];
//                [cell.iconImage setHighlightedImage:nil];
//            }
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"favoriteRoutes"]) {
//            [cell.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
//            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
//        } else if ([[currentRow objectForKey:@"source"] isEqualToString:@"pastRoutes"]) {
//            [cell.iconImage setImage:[UIImage imageNamed:@"findHistory"]];
//            [cell.iconImage setHighlightedImage:[UIImage imageNamed:@"findHistory"]];
//        }
        return cell;
    }
}

- (void)openCloseSection:(NSInteger)section {
    if (section == 0) {
        favoritesOpen = !favoritesOpen;
    } else if (section == 1) {
        historyOpen = !historyOpen;
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
}

- (NSString*)textFromItem:(NSObject<SearchListItem> *)item {
    NSMutableArray * arr = [NSMutableArray array];
    [arr addObject:item.name];
    if (item.address && ![item.name isEqualToString:item.address]) {
        NSString * s = [item.address stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([s isEqualToString:@""] == NO) {
            [arr addObject:s];
        }
    }
    return [arr componentsJoinedByString:@", "];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self isCountButton:indexPath]) {
        [self openCloseSection:indexPath.section];
    } else {
        if (indexPath.section == 0) {
            if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Search" withLabel:@"Favorites" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        } else {
            if (![SMAnalytics trackEventWithCategory:@"Route" withAction:@"Search" withLabel:@"Recent" withValue:0]) {
                debugLog(@"error in trackEvent");
            }
        }
        NSObject<SearchListItem> *currentItem = [[self.groupedList objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        self.toItem = currentItem;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCountButton:indexPath]) {
        return 47.0f;
    } else {
        return 45.0f;
    }
    return [SMEnterRouteCell getHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [SMAutocompleteHeader getHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SMAutocompleteHeader * cell = [tableView dequeueReusableCellWithIdentifier:@"autocompleteHeader"];
    switch (section) {
        case 0:
            [cell.headerTitle setText:@"favorites".localized];
            break;
        case 1:
            [cell.headerTitle setText:@"recent_results".localized];
            break;            
        default:
            break;
    }
    return cell;
}


#pragma mark - search delegate 

- (void)locationFound:(NSObject<SearchListItem> *)locationItem {
    switch (delegateField) {
        case fieldTo:
            self.toItem = locationItem;
            break;
        case fieldFrom:
            self.fromItem = locationItem;
            break;
        default:
            break;
    }
}



#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


@end
