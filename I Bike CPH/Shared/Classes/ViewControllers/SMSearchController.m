//
//  SMSearchController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "DAKeyboardControl.h"
#import "SMAPIQueue.h"
#import "SMAddressParser.h"
#import "SMAppDelegate.h"
#import "SMFavoritesUtil.h"
#import "SMGeocoder.h"
#import "SMLocationManager.h"
#import "SMRequestOSRM.h"
#import "SMRouteUtils.h"
#import "SMSearchCell.h"
#import "SMSearchController.h"
#import "SMSearchTwoRowCell.h"
#import "SMUtil.h"
#import "TTTAttributedLabel.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface SMSearchController ()

@property(weak, nonatomic) IBOutlet UITextField *searchField;
@property(weak, nonatomic) IBOutlet UITableView *tableView;
@property(weak, nonatomic) IBOutlet UIView *loaderView;

@property(nonatomic, strong) NSArray *searchResults;
@property(nonatomic, strong) NSMutableArray *tempSearch;
@property(nonatomic, strong) NSArray *favorites;

@property(nonatomic, strong) NSArray *terms;
@property(nonatomic, strong) NSString *srchString;
@property(nonatomic, strong) SMRequestOSRM *req;

@property(nonatomic, strong) SMAPIQueue *queue;
@end

static NSString *const SingleRowSearchCellIdentifier = @"searchCell";
static NSString *const TwoRowSearchCellIdentifier = @"searchTwoRowsCell";

@implementation SMSearchController

- (id)init
{
    self = [super init];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (void)dealloc
{
    [self.queue stopAllRequests];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"search".localized;

    [self.searchField setText:self.searchText];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.searchField becomeFirstResponder];
    [self setFavorites:[SMFavoritesUtil getFavorites]];

    self.queue = [[SMAPIQueue alloc] initWithMaxOperations:3];
    self.queue.delegate = self;

    [self setReturnKey];
}

- (void)setReturnKey
{
    if (self.locationItem) {
        [self.searchField setReturnKeyType:UIReturnKeyGo];
        [self.searchField resignFirstResponder];
        [self.searchField becomeFirstResponder];
    }
    else {
        [self.searchField setReturnKeyType:UIReturnKeyDone];
        [self.searchField resignFirstResponder];
        [self.searchField becomeFirstResponder];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    UITableView *tbl = self.tableView;
    UIView *fade = self.loaderView;

    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
      [tbl setFrame:CGRectMake(0.0f, tbl.frame.origin.y, tbl.frame.size.width, keyboardFrameInView.origin.y - tbl.frame.origin.y)];
      [fade setFrame:tbl.frame];
      debugLog(@"%@", NSStringFromCGRect(keyboardFrameInView));
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}

#pragma mark - Setters and Getters

- (void)setLocationItem:(NSObject<SearchListItem> *)locationItem
{
    if (locationItem != _locationItem) {
        _locationItem = locationItem;

        NSString *prePopulatedString = nil;
        if (self.locationItem.type != SearchListItemTypeCurrentLocation) {
            prePopulatedString = locationItem.name;
        }
        self.searchField.text = prePopulatedString;
    }
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchResults count];
}

- (NSArray *)getSearchTerms
{
    UnknownSearchListItem *item = [SMAddressParser parseAddress:self.searchField.text];
    NSString *search =
        [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@", item.name, item.address, item.street, item.number, item.zip, item.city, item.country];
    search = [search stringByReplacingOccurrencesOfString:@"  " withString:@" "];  // Remove double spacing
    NSMutableCharacterSet *set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [set addCharactersInString:@","];
    search = [search stringByTrimmingCharactersInSet:set];

    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"[,\\s]+" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSMutableString *separatedSearch = [NSMutableString stringWithString:search];
    [exp replaceMatchesInString:separatedSearch options:0 range:NSMakeRange(0, [search length]) withTemplate:@" "];
    return [separatedSearch componentsSeparatedByString:@" "];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject<SearchListItem> *item = [self.searchResults objectAtIndex:indexPath.row];

    NSArray *words = [self getSearchTerms];

    BOOL isFromStreetSearch = false;

    SMSearchCell *cell;
    if (item.type == SearchListItemTypeCurrentLocation) {
        cell = [tableView dequeueReusableCellWithIdentifier:SingleRowSearchCellIdentifier];
        cell.nameLabel.text = item.name;
    }
    else if (item.type == SearchListItemTypeKortfor) {
        SMSearchTwoRowCell *twoCell = [tableView dequeueReusableCellWithIdentifier:TwoRowSearchCellIdentifier];

        KortforItem *kortforItem = (KortforItem *)item;
        isFromStreetSearch = kortforItem.isFromStreetSearch;

        NSString *name = isFromStreetSearch ? item.street : [NSString stringWithFormat:@"%@ %@", item.street, item.number];
        NSString *address = [NSString stringWithFormat:@"%@ %@", item.zip, item.city];

        [twoCell.nameLabel setText:name
            afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
              for (NSString *srch in words) {
                  NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];

                  twoCell.nameLabel.textColor = [UIColor lightGrayColor];
                  UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.nameLabel.font.pointSize];
                  CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);

                  if (font) {
                      [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                      CFRelease(font);
                      [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName
                                                      value:[UIColor colorWithWhite:0.0f alpha:1.0f]
                                                      range:boldRange];
                  }
              }
              return mutableAttributedString;
            }];

        [twoCell.addressLabel setText:address
            afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {

              for (NSString *srch in words) {
                  NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];

                  if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                      UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.addressLabel.font.pointSize];

                      CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);

                      if (font) {
                          [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                          CFRelease(font);
                          [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName
                                                          value:[UIColor colorWithWhite:0.0f alpha:1.0f]
                                                          range:boldRange];
                      }
                  }
              }
              return mutableAttributedString;
            }];
        cell = twoCell;
    }
    else if (![item.name isEqualToString:item.address] && item.address != nil && ![item.address isEqualToString:@""]) {
        SMSearchTwoRowCell *twoCell = [tableView dequeueReusableCellWithIdentifier:TwoRowSearchCellIdentifier];

        [twoCell.nameLabel setText:item.name
            afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
              for (NSString *srch in words) {
                  NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];

                  twoCell.nameLabel.textColor = [UIColor lightGrayColor];
                  UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.nameLabel.font.pointSize];
                  CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);

                  if (font) {
                      [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                      CFRelease(font);
                      [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName
                                                      value:[UIColor colorWithWhite:0.0f alpha:1.0f]
                                                      range:boldRange];
                  }
              }
              return mutableAttributedString;
            }];

        [twoCell.addressLabel setText:item.address
            afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {

              for (NSString *srch in words) {
                  NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];

                  if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                      UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.addressLabel.font.pointSize];

                      CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);

                      if (font) {
                          [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                          CFRelease(font);
                          [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName
                                                          value:[UIColor colorWithWhite:0.0f alpha:1.0f]
                                                          range:boldRange];
                      }
                  }
              }
              return mutableAttributedString;
            }];
        cell = twoCell;
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:SingleRowSearchCellIdentifier];

        [cell.nameLabel setText:item.name
            afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
              for (NSString *srch in words) {
                  NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];

                  cell.nameLabel.textColor = [UIColor lightGrayColor];
                  UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                  CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);

                  if (font) {
                      [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                      CFRelease(font);
                      [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName
                                                      value:[UIColor colorWithWhite:0.0f alpha:1.0f]
                                                      range:boldRange];
                  }
              }
              return mutableAttributedString;
            }];
    }

    if (item.type == SearchListItemTypeFavorite) {
        [cell setImageWithFavoriteType:((FavoriteItem *)item).origin];
    }
    else {
        [cell setImageWithType:item.type isFromStreetSearch:isFromStreetSearch];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSObject<SearchListItem> *currentItem = self.searchResults[indexPath.row];
    self.locationItem = currentItem;
    [self setReturnKey];

    if (currentItem.type == SearchListItemTypeKortfor && ((KortforItem *)currentItem).isFromStreetSearch) {
        self.searchField.text = currentItem.address;
        NSString *street = currentItem.street;
        if (street.length > 0) {
            [self stopAll];
            [self delayedAutocomplete:self.searchField.text];
            [self setCaretForSearchFieldOnPosition:street.length + 1];
        }
        else {
            [self checkLocation];
        }
    }
    else if (currentItem.type == SearchListItemTypeCurrentLocation) {
        if ([SMLocationManager instance].hasValidLocation) {
            CLLocation *loc = [SMLocationManager instance].lastValidLocation;
            if (loc) {
                [self dismiss];
            }
        }
    }
    else {
        if (self.delegate) {
            [self.delegate locationFound:currentItem];
        }
        [self dismiss];
    }
}

#pragma mark - custom methods

- (void)stopAll
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAutocomplete:) object:nil];
    self.searchResults = @[];
    self.tempSearch = [NSMutableArray array];
    [self.queue stopAllRequests];
}

- (void)delayedAutocomplete:(NSString *)text
{
    [self.loaderView setAlpha:1.0f];
    [self.tableView reloadData];
    [self.queue addTasks:[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)showFade
{
    [self.loaderView setAlpha:1.0f];
}

- (void)hideFade
{
    [UIView animateWithDuration:0.2f
        delay:1.0f
        options:UIViewAnimationOptionBeginFromCurrentState
        animations:^{
          self.loaderView.alpha = 0.0f;
        }
        completion:^(BOOL finished){
        }];
}

- (void)checkLocation
{
    if ([self.searchField.text isEqualToString:@""] == NO) {
        if ([self.searchField.text isEqualToString:CURRENT_POSITION_STRING]) {
        }
        else {
            [self.loaderView setAlpha:1.0f];
            if (self.locationItem && self.locationItem.location) {
                if (self.delegate) {
                    [self.delegate locationFound:self.locationItem];
                    [self dismiss];
                }
                [self hideFade];
            }
            else {
                [self hideFade];
                if (self.searchResults && self.searchResults.count > 0) {
                    NSObject<SearchListItem> *currentItem = [self.searchResults objectAtIndex:0];
                    if (currentItem.type == SearchListItemTypeCurrentLocation) {
                        currentItem = nil;
                        if (self.searchResults && self.searchResults.count > 1) {
                            currentItem = [self.searchResults objectAtIndex:1];
                        }
                    }
                    if (currentItem) {
                        self.searchField.text = currentItem.name;
                        self.locationItem = currentItem;

                        if (self.delegate) {
                            [self.delegate locationFound:self.locationItem];
                            [self dismiss];
                        }
                    }
                }
            }
        }
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
        });
    }
}

- (void)setCaretForSearchFieldOnPosition:(NSInteger)num
{
    UITextPosition *position = [self.searchField positionFromPosition:self.searchField.beginningOfDocument offset:num];
    UITextRange *textRange = [self.searchField textRangeFromPosition:position toPosition:position];
    [self.searchField setSelectedTextRange:textRange];
}

#pragma mark - textfield delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *searchString = [textField.text stringByReplacingCharactersInRange:range withString:string].capitalizedString;
    if ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            isEqualToString:[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] == NO) {
        _locationItem = nil;
    }
    [self stopAll];
    if (searchString.length >= 2) {
        [self delayedAutocomplete:searchString];
    }
    else if (searchString.length == 1) {
        if (self.shouldAllowCurrentPosition) {
            CurrentLocationItem *currentLocationItem = [CurrentLocationItem new];
            self.searchResults = @[ currentLocationItem ];
        }
        else {
            self.searchResults = nil;
        }
        [self.tableView reloadData];
        self.loaderView.alpha = 0.0f;
    }
    else {
        self.searchResults = @[];
        [self.tableView reloadData];
        self.loaderView.alpha = 0.0f;
    }

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.locationItem = nil;
    [self setReturnKey];
    textField.text = @"";
    [self autocompleteEntriesFound:@[] forString:@""];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self checkLocation];
    return YES;
}

#pragma mark - smautocomplete delegate

- (void)autocompleteEntriesFound:(NSArray *)foundEntries forString:(NSString *)str
{
    @synchronized(self.searchResults)
    {
        SMAppDelegate *appDelegate = (SMAppDelegate *)[UIApplication sharedApplication].delegate;
        NSMutableArray *combinedResults = [NSMutableArray new];

        if ([str isEqualToString:@""]) {
            self.searchResults = combinedResults;
            [self.tableView reloadData];
            [self.loaderView setAlpha:0.0f];
            return;
        }

        self.terms = [self.srchString componentsSeparatedByString:@" "];

        // Current location
        if (self.shouldAllowCurrentPosition) {
            CurrentLocationItem *currentLocationItem = [CurrentLocationItem new];
            [combinedResults insertObject:currentLocationItem atIndex:0];
        }

        // Favorites
        for (int i = 0; i < self.favorites.count; i++) {
            id<SearchListItem> d = self.favorites[i];
            if ([SMRouteUtils pointsForName:d.name andAddress:d.address andTerms:str] > 0) {
                [combinedResults addObject:d];
            }
        }

        // History
        for (int i = 0; i < appDelegate.searchHistory.count; i++) {
            BOOL found = NO;
            id<SearchListItem> d = appDelegate.searchHistory[i];
            for (id<SearchListItem> d1 in combinedResults) {
                if ([d1.name isEqualToString:d.name] && [d1.address isEqualToString:d.address]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO && [SMRouteUtils pointsForName:d.name andAddress:d.address andTerms:str] > 0) {
                [combinedResults addObject:d];
            }
        }

        // From external search
        NSMutableArray *externalResults = foundEntries.mutableCopy;
        [externalResults sortUsingComparator:^NSComparisonResult(NSObject<SearchListItem> *obj1, NSObject<SearchListItem> *obj2) {
          CLLocation *currentLocation = [SMLocationManager instance].lastValidLocation;

          SEL distanceSelector = @selector(distance);
          NSString *distanceSelectorString = NSStringFromSelector(distanceSelector);

          double dist1 = 0.0f;
          double dist2 = 0.0f;
          if ([obj1 respondsToSelector:distanceSelector]) {
              dist1 = [[obj1 valueForKey:distanceSelectorString] doubleValue];
          }
          else {
              dist1 = [obj1.location distanceFromLocation:currentLocation];
          }
          if ([obj2 respondsToSelector:distanceSelector]) {
              dist2 = [[obj2 valueForKey:distanceSelectorString] doubleValue];
          }
          else {
              dist2 = [obj2.location distanceFromLocation:currentLocation];
          }
          if (dist1 > dist2) {
              return NSOrderedDescending;
          }
          else if (dist1 < dist2) {
              return NSOrderedAscending;
          }
          else {
              return NSOrderedSame;
          }
        }];
        for (id<SearchListItem> d in externalResults) {
            BOOL found = NO;
            for (id<SearchListItem> d1 in combinedResults) {
                if ([d1.name isEqualToString:d.name] && [d1.address isEqualToString:d.address]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO) {
                [combinedResults addObject:d];
            }
        }

        self.searchResults = combinedResults;
        [self.tableView reloadData];
        [self.loaderView setAlpha:0.0f];
    }
}

#pragma mark - api operation delegate

- (void)queuedRequest:(SMAPIOperation *)object failedWithError:(NSError *)error
{
    [self autocompleteEntriesFound:self.tempSearch forString:object.searchString];
    [self hideFade];
}

static NSString *const sourceOiorest = @"oiorest";

- (void)queuedRequest:(SMAPIOperation *)object finishedWithResult:(id)result
{
    [self.tempSearch addObjectsFromArray:result];
    [self autocompleteEntriesFound:self.tempSearch forString:object.searchString];

    [self hideFade];
}

#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
