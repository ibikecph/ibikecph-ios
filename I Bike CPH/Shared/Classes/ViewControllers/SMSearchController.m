//
//  SMSearchController.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSearchController.h"
#import "SMSearchCell.h"
#import "SMSearchTwoRowCell.h"
#import <CoreLocation/CoreLocation.h>
#import "SMGeocoder.h"
#import <MapKit/MapKit.h>
#import "SMAppDelegate.h"
#import "SMAutocomplete.h"
#import "DAKeyboardControl.h"
#import "TTTAttributedLabel.h"
#import "SMLocationManager.h"
#import "SMUtil.h"
#import "SMRouteUtils.h"
#import "SMRequestOSRM.h"
#import "SMFavoritesUtil.h"
#import "SMAPIQueue.h"
#import "SMAddressParser.h"

@interface SMSearchController ()

@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *loaderView;

@property (nonatomic, strong) NSArray * searchResults;
@property (nonatomic, strong) NSMutableArray * tempSearch;
@property (nonatomic, strong) SMAutocomplete * autocomp;
@property (nonatomic, strong) NSArray * favorites;

@property (nonatomic, strong) NSMutableArray * terms;
@property (nonatomic, strong) NSString * srchString;
@property (nonatomic, strong) SMRequestOSRM * req;

@property (nonatomic, strong) SMAPIQueue * queue;
@end

static NSString *const SingleRowSearchCellIdentifier = @"searchCell";
static NSString *const TwoRowSearchCellIdentifier = @"searchTwoRowsCell";

@implementation SMSearchController

- (id)init {
    self = [super init];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.shouldAllowCurrentPosition = YES;
    }
    return self;
}

- (void)dealloc {
    [self.queue stopAllRequests];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"search".localized;
    
    [self.searchField setText:self.searchText];
    self.autocomp = [[SMAutocomplete alloc] initWithDelegate:self];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.searchField becomeFirstResponder];
    [self setFavorites:[SMFavoritesUtil getFavorites]];
    
    self.queue = [[SMAPIQueue alloc] initWithMaxOperations:3];
    self.queue.delegate = self;
    
    [self setReturnKey];
    
}

- (void)setReturnKey {
    if (self.locationItem) {
        [self.searchField setReturnKeyType:UIReturnKeyGo];
        [self.searchField resignFirstResponder];
        [self.searchField becomeFirstResponder];
    } else {
        [self.searchField setReturnKeyType:UIReturnKeyDone];
        [self.searchField resignFirstResponder];
        [self.searchField becomeFirstResponder];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UITableView * tbl = self.tableView;
    UIView * fade = self.loaderView;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView, BOOL opening, BOOL closing) {
        [tbl setFrame:CGRectMake(0.0f, tbl.frame.origin.y, tbl.frame.size.width, keyboardFrameInView.origin.y - tbl.frame.origin.y)];
        [fade setFrame:tbl.frame];
        debugLog(@"%@", NSStringFromCGRect(keyboardFrameInView));
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeKeyboardControl];
    [super viewWillDisappear:animated];
}


#pragma mark - Setters and Getters 

- (void)setLocationItem:(NSObject<SearchListItem> *)locationItem {
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResults count];
}

- (NSArray*)getSearchTerms {
    UnknownSearchListItem *item = [SMAddressParser parseAddress:self.searchField.text];
    NSString * search = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@", item.name, item.address, item.street, item.number, item.zip, item.city, item.country];
    search = [search stringByReplacingOccurrencesOfString:@"  " withString:@" "]; // Remove double spacing
    NSMutableCharacterSet * set = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [set addCharactersInString:@","];
    search = [search stringByTrimmingCharactersInSet:set];
    
    NSRegularExpression * exp = [NSRegularExpression regularExpressionWithPattern:@"[,\\s]+" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSMutableString * separatedSearch = [NSMutableString stringWithString:search];
    [exp replaceMatchesInString:separatedSearch options:0 range:NSMakeRange(0, [search length]) withTemplate:@" "];
    return [separatedSearch componentsSeparatedByString:@" "];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject<SearchListItem> *item = [self.searchResults objectAtIndex:indexPath.row];
   
    NSArray * words = [self getSearchTerms];

    SMSearchCell * cell;
    if (item.type == SearchListItemTypeCurrentLocation)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SingleRowSearchCellIdentifier];
        cell.nameLabel.text = item.name;
    }
    else if (item.type == SearchListItemTypeKortfor) {
        SMSearchTwoRowCell *twoCell = [tableView dequeueReusableCellWithIdentifier:TwoRowSearchCellIdentifier];
        
        NSString *name;
        NSString *address;
        
        name = item.name;
        address = [NSString stringWithFormat:@"%@ %@", item.zip, item.city];
        
        [twoCell.nameLabel setText:name afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                twoCell.nameLabel.textColor = [UIColor lightGrayColor];
                UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.nameLabel.font.pointSize];
                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                
                if (font) {
                    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                    CFRelease(font);
                    [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                }
            }
            return mutableAttributedString;
        }];
        
        [twoCell.addressLabel setText:address afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.addressLabel.font.pointSize];
                    
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                    
                }
            }
            return mutableAttributedString;
        }];
        cell = twoCell;
    }
    else if (![item.name isEqualToString:item.address] &&
        item.address != nil &&
        ![item.address isEqualToString:@""])
    {
        SMSearchTwoRowCell *twoCell = [tableView dequeueReusableCellWithIdentifier:TwoRowSearchCellIdentifier];
        
        [twoCell.nameLabel setText:item.name afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                twoCell.nameLabel.textColor = [UIColor lightGrayColor];
                UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.nameLabel.font.pointSize];
                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                
                if (font) {
                    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                    CFRelease(font);
                    [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                }
            }
            return mutableAttributedString;
        }];
        
        [twoCell.addressLabel setText:item.address afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                if (boldRange.length > 0 && boldRange.location != NSNotFound) {
                    UIFont *boldSystemFont = [UIFont systemFontOfSize:twoCell.addressLabel.font.pointSize];
                    
                    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                    
                    if (font) {
                        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                        CFRelease(font);
                        [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                    }
                    
                }
            }
            return mutableAttributedString;
        }];
        cell = twoCell;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SingleRowSearchCellIdentifier];
        
        [cell.nameLabel setText:item.name afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            for (NSString * srch in words) {
                NSRange boldRange = [[mutableAttributedString string] rangeOfString:srch options:NSCaseInsensitiveSearch];
                
                cell.nameLabel.textColor = [UIColor lightGrayColor];
                UIFont *boldSystemFont = [UIFont systemFontOfSize:cell.nameLabel.font.pointSize];
                CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
                
                if (font) {
                    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:boldRange];
                    CFRelease(font);
                    [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:[UIColor colorWithWhite:0.0f alpha:1.0f] range:boldRange];
                }
            }
            return mutableAttributedString;
        }];
    }
    
    if (item.type == SearchListItemTypeFavorite) {
        [cell setImageWithFavoriteType:((FavoriteItem *)item).origin];
    } else {
        [cell setImageWithType:item.type];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSObject<SearchListItem> *currentItem = [self.searchResults objectAtIndex:indexPath.row];
    self.locationItem = currentItem;
    [self setReturnKey];
    

    if (currentItem.type == SearchListItemTypeKortfor) { // TODO: Check if oiorest/kortfor + autocomplete
        self.searchField.text = currentItem.address;
        NSString * street = currentItem.street;
        if(street.length > 0) {
            [self stopAll];
            [self delayedAutocomplete:self.searchField.text];
            // TODO: Carret position doesn't set correctly
            [self setCaretForSearchFieldOnPosition:@(street.length+1)];
        } else {
            [self checkLocation];
        }
    } else if (currentItem.type == SearchListItemTypeCurrentLocation) {
        if ([SMLocationManager instance].hasValidLocation) {
            CLLocation *loc = [SMLocationManager instance].lastValidLocation;
            if (loc) {
                [self dismiss];
            }
        }
    } else {
        if (self.delegate) {
            [self.delegate locationFound:self.locationItem];
        }
        [self dismiss];
    }
    
    // TODO: From CykelPlanen for l283-308
//    if ([[currentRow objectForKey:@"source"] isEqualToString:@"autocomplete"] && [[currentRow objectForKey:@"subsource"] isEqualToString:@"oiorest"]) {
//        self.searchField.text = [currentRow objectForKey:@"address"];
//        NSString * street = [currentRow objectForKey:@"street"];
//        if(street.length > 0){
//            [self setCaretForSearchFieldOnPosition:[NSNumber numberWithInt:street.length+1]];
//        } else {
//            [self checkLocation];
//        }
//    } else if (currentItem.type == SearchListItemTypeCurrentLocation) {
//        SMRequestOSRM * r = [[SMRequestOSRM alloc] initWithDelegate:self];
//        [r setRequestIdentifier:@"getNearestForPinDrop"];
//        [r findNearestPointForLocation:[[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]]];
//    } else {
//        if ([currentRow objectForKey:@"subsource"]) {
//            [self setLocationData:@{
//                                    @"name" : [currentRow objectForKey:@"name"],
//                                    @"address" : [currentRow objectForKey:@"address"],
//                                    @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]],
//                                    @"source" : [currentRow objectForKey:@"source"],
//                                    @"subsource" : [currentRow objectForKey:@"subsource"]
//                                    }];
//        } else {
//            [self setLocationData:@{
//                                    @"name" : [currentRow objectForKey:@"name"],
//                                    @"address" : [currentRow objectForKey:@"address"],
//                                    @"location" : [[CLLocation alloc] initWithLatitude:[[currentRow objectForKey:@"lat"] doubleValue] longitude:[[currentRow objectForKey:@"long"] doubleValue]],
//                                    @"source" : [currentRow objectForKey:@"source"]
//                                    }];
//        }
//        if (self.delegate) {
//            [self.delegate locationFound:self.locationItem];
//        }
//        [self goBack:nil];
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SMSearchCell getHeight];
}

#pragma mark - custom methods 

- (void)stopAll {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAutocomplete:) object:nil];
    self.searchResults = @[];
    self.tempSearch = [NSMutableArray array];
    [self.queue stopAllRequests];
}

- (void)delayedAutocomplete:(NSString*)text {
    [self.loaderView setAlpha:1.0f];
    [self.tableView reloadData];
    [self.queue addTasks:[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    
    // TODO: From Cykelplanen for l362-363
//    [self.autocomp getAutocomplete:text];
}

- (void)showFade {
    [self.loaderView setAlpha:1.0f];
}

- (void)hideFade {
    [UIView animateWithDuration:0.2f delay:1.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.loaderView.alpha = 0.0f;
    } completion:^(BOOL finished) {
    }];
}

- (void)checkLocation {
    if ([self.searchField.text isEqualToString:@""] == NO) {
        if ([self.searchField.text isEqualToString:CURRENT_POSITION_STRING]) {
            
        } else {
            [self.loaderView setAlpha:1.0f];
            if (self.locationItem && self.locationItem.location) {
                if (self.delegate) {
                    [self.delegate locationFound:self.locationItem];
                    [self dismiss];
                }
                [self hideFade];
            } else {
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
            
            // TODO: From CykelPlanel for l386-413
//            [SMGeocoder geocode:self.searchField.text completionHandler:^(NSArray *placemarks, NSError *error) {
//                if ([placemarks count] > 0) {
//                    MKPlacemark *coord = [placemarks objectAtIndex:0];
//                    [self dismiss];
//                    if (self.delegate) {
//                        [self.delegate locationFound:@{
//                                                       @"name" : self.searchField.text,
//                                                       @"address" : self.searchField.text,
//                                                       @"location" : [[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude],
//                                                       @"source" : @"typedIn"
//                                                       }];
//                    }
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
//                    });
//                } else {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
//                    });
//                }
//            }];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(hideFade) withObject:nil afterDelay:0.01f];
        });
    }
}



- (void) setCaretForSearchFieldOnPosition:(NSNumber*) pos{
    //If pos is > 0 that means that this is a first call.
    //First call will be used to set cursor to begining and call recursively this method again with delay to set real position
    int num = [pos intValue];
    if(num > 0){
        UITextPosition * from = [self.searchField positionFromPosition:[self.searchField beginningOfDocument] offset:0];
        UITextPosition * to =[self.searchField positionFromPosition:[self.searchField beginningOfDocument] offset:0];
        [self.searchField setSelectedTextRange:[self.searchField textRangeFromPosition:from toPosition:to]];
        NSNumber * newPos = [NSNumber numberWithInt:-num];
        [self performSelector:@selector(setCaretForSearchFieldOnPosition:) withObject:newPos afterDelay:0.3];
    } else {
        num = -num;
        UITextPosition * from = [self.searchField positionFromPosition:[self.searchField beginningOfDocument] offset:num];
        UITextPosition * to =[self.searchField positionFromPosition:[self.searchField beginningOfDocument] offset:num];
        [self.searchField setSelectedTextRange:[self.searchField textRangeFromPosition:from toPosition:to]];
    }
}

#pragma mark - textfield delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString * s = [[textField.text stringByReplacingCharactersInRange:range withString:string] capitalizedString];
    if ([[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] == NO) {
        _locationItem = nil;
//        [self setReturnKey];
    }
    [self stopAll];
    if ([s length] >= 2) {
        [self delayedAutocomplete:s];
        [self performSelector:@selector(delayedAutocomplete:) withObject:s afterDelay:0.5f];
    } else if ([s length] == 1) {
        NSMutableArray * r = [NSMutableArray array];
        if (self.shouldAllowCurrentPosition) {
            CurrentLocationItem *currentLocationItem = [CurrentLocationItem new];
            [r insertObject:currentLocationItem atIndex:0];
        }
        self.searchResults = r;
        [self.tableView reloadData];
        self.loaderView.alpha = 0.0f;
    } else {
        self.searchResults = @[];
        [self.tableView reloadData];
        self.loaderView.alpha = 0.0f;
    }
    
    // TODO: From CykelPlanen for l478-499
//    if ([s isEqualToString:@""]) {
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAutocomplete:) object:nil];
//        [self autocompleteEntriesFound:@[] forString:@""];
//    } else {
//        if ([s length] >= 2) {
//            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedAutocomplete:) object:nil];
//            [self performSelector:@selector(delayedAutocomplete:) withObject:s afterDelay:0.5f];
//        } else if ([s length] >= 1) {
//            NSMutableArray * r = [NSMutableArray array];
//            if (self.shouldAllowCurrentPosition) {
//                [r insertObject:@{
//                                  @"name" : CURRENT_POSITION_STRING,
//                                  @"address" : CURRENT_POSITION_STRING,
//                                  @"startDate" : [NSDate date],
//                                  @"endDate" : [NSDate date],
//                                  @"lat" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.latitude],
//                                  @"long" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.longitude],
//                                  @"source" : @"currentPosition",
//                                  } atIndex:0];
//            }
//            self.searchResults = r;
//            [self.tableView reloadData];
//        }
//    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.locationItem = nil;
    [self setReturnKey];
    textField.text = @"";
    [self autocompleteEntriesFound:@[] forString:@""];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self checkLocation];
    return YES;
}

#pragma mark - smautocomplete delegate

- (void)autocompleteEntriesFound:(NSArray *)arr forString:(NSString*) str {
    @synchronized(self.searchResults) {
        
        SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
        NSMutableArray * r = [NSMutableArray array];
        
        if ([str isEqualToString:@""]) {
            self.searchResults = r;
            [self.tableView reloadData];
            [self.loaderView setAlpha:0.0f];
            return;
        }
        
//        if ([[str lowercaseString] isEqualToString:[self.searchField.text lowercaseString]] == NO) {
//            return;
//        }
        
        self.terms = [NSMutableArray array];
        self.srchString = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for (NSString * str in [self.srchString componentsSeparatedByString:@" "]) {
            if ([self.terms indexOfObject:str] == NSNotFound) {
                [self.terms addObject:str];
            }
        }
        
        // Check if address and name isn't already in results array
        for (id<SearchListItem> d in arr) {
            BOOL found = NO;
            for (id<SearchListItem> d1 in r) {
                if ([d1.name isEqualToString:d.name] &&
                    [d1.address isEqualToString:d.address]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO) {
                [r addObject:d];                
            }
        }
        
        
        for (int i = 0; i < [self.favorites count]; i++) {
            BOOL found = NO;
            id<SearchListItem> d = [self.favorites objectAtIndex:i];
            for (id<SearchListItem>  d1 in r) {
                if ([d1.name isEqualToString:d.name] &&
                    [d1.address isEqualToString:d.address]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO && [SMRouteUtils pointsForName:d.name andAddress:d.address andTerms:str] > 0) {
                [r addObject:d];
            }
        }
        
        for (int i = 0; i < [appd.searchHistory count]; i++) {
            BOOL found = NO;
            id<SearchListItem> d = [appd.searchHistory objectAtIndex:i];
            for (id<SearchListItem> d1 in r) {
                if ([d1.name isEqualToString:d.name] &&
                    [d1.address isEqualToString:d.address]) {
                    found = YES;
                    break;
                }
            }
            if (found == NO && [SMRouteUtils pointsForName:d.name andAddress:d.address andTerms:str] > 0) {
                debugLog(@"Object: %@\nString: %@\npoints: %ld\n", d, str, (long)[SMRouteUtils pointsForName:d.name andAddress:d.address andTerms:str]);
                [r addObject:d];
            }
        }
        
        [r sortUsingComparator:^NSComparisonResult(NSObject<SearchListItem> *obj1, NSObject<SearchListItem> *obj2) {
            CLLocation *currentLocation = [SMLocationManager instance].lastValidLocation;
            
            SEL distanceSelector = @selector(distance);
            NSString *distanceSelectorString = NSStringFromSelector(distanceSelector);
            
            double dist1 = 0.0f;
            double dist2 = 0.0f;
            if ([obj1 respondsToSelector:distanceSelector]) {
                dist1 = [[obj1 valueForKey:distanceSelectorString] doubleValue];
            } else {
                dist1 = [obj1.location distanceFromLocation:currentLocation];
            }
            if ([obj2 respondsToSelector:distanceSelector]) {
                dist2 = [[obj2 valueForKey:distanceSelectorString] doubleValue];
            } else {
                dist2 = [obj2.location distanceFromLocation:currentLocation];
            }
            if (dist1 > dist2) {
                return NSOrderedDescending;
            } else if (dist1 < dist2) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
        }];
        
        if (self.shouldAllowCurrentPosition) {
            CurrentLocationItem *currentLocationItem = [CurrentLocationItem new];
            [r insertObject:currentLocationItem atIndex:0];
        }
        
        
        self.searchResults = r;
        [self.tableView reloadData];
        [self.loaderView setAlpha:0.0f];
    }
}

#pragma mark - api operation delegate

-(void)queuedRequest:(SMAPIOperation *)object failedWithError:(NSError *)error {
    [self autocompleteEntriesFound:self.tempSearch forString:object.searchString];
    [self hideFade];
}


static NSString *const sourceOiorest = @"oiorest";

- (void)queuedRequest:(SMAPIOperation *)object finishedWithResult:(id)result {
    [self.tempSearch addObjectsFromArray:result];
    [self autocompleteEntriesFound:self.tempSearch forString:object.searchString];
    
    [self hideFade];
}

// TODO: From CykelPlanen for l545- 671
//- (void)autocompleteEntriesFound:(NSArray *)arr forString:(NSString*) str {
//    [self hideFade];
//    
//    SMAppDelegate * appd = (SMAppDelegate*)[UIApplication sharedApplication].delegate;
//    NSMutableArray * r = [NSMutableArray array];
//    
//    if ([str isEqualToString:@""]) {
//        self.searchResults = r;
//        [self.tableView reloadData];
//        [self.loaderView setAlpha:0.0f];
//        return;
//    }
//    
//    if ([[str lowercaseString] isEqualToString:[self.searchField.text lowercaseString]] == NO) {
//        return;
//    }
//    
//    self.terms = [NSMutableArray array];
//    self.srchString = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    for (NSString * str in [self.srchString componentsSeparatedByString:@" "]) {
//        if ([self.terms indexOfObject:str] == NSNotFound) {
//            [self.terms addObject:str];
//        }
//    }
//    
//    for (NSDictionary * d in arr) {
//        [r addObject:d];
//    }
//    
//    for (int i = 0; i < [self.favorites count]; i++) {
//        BOOL found = NO;
//        NSDictionary * d = [self.favorites objectAtIndex:i];
//        for (NSDictionary * d1 in r) {
//            if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
//                found = YES;
//                break;
//            }
//        }
//        if (found == NO && [SMRouteUtils pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str] > 0) {
//            [r addObject:d];
//        }
//    }
//    
//    for (int i = 0; i < [appd.searchHistory count]; i++) {
//        BOOL found = NO;
//        NSDictionary * d = [appd.searchHistory objectAtIndex:i];
//        for (NSDictionary * d1 in r) {
//            if ([[d1 objectForKey:@"address"] isEqualToString:[d objectForKey:@"address"]]) {
//                found = YES;
//                break;
//            }
//        }
//        if (found == NO && [SMRouteUtils pointsForName:[d objectForKey:@"name"] andAddress:[d objectForKey:@"address"] andTerms:str] > 0) {
//            [r addObject:d];
//        }
//    }
//    
//    [r sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
//        NSComparisonResult cmp = [[obj1 objectForKey:@"order"] compare:[obj2 objectForKey:@"order"]];
//        if (cmp == NSOrderedSame) {
//            cmp = [[obj2 objectForKey:@"relevance"] compare:[obj1 objectForKey:@"relevance"]];
//            if (cmp == NSOrderedSame) {
//                if ([obj1 objectForKey:@"lat"] && [obj1 objectForKey:@"long"] && [obj2 objectForKey:@"lat"] && [obj2 objectForKey:@"long"] && [SMLocationManager instance].hasValidLocation) {
//                    CGFloat dist1 = [[[CLLocation alloc] initWithLatitude:[[obj1 objectForKey:@"lat"] doubleValue]  longitude:[[obj1 objectForKey:@"long"] doubleValue]] distanceFromLocation:[SMLocationManager instance].lastValidLocation];
//                    CGFloat dist2 = [[[CLLocation alloc] initWithLatitude:[[obj2 objectForKey:@"lat"] doubleValue]  longitude:[[obj2 objectForKey:@"long"] doubleValue]] distanceFromLocation:[SMLocationManager instance].lastValidLocation];
//                    
//                    if (dist1 > dist2) {
//                        cmp = NSOrderedDescending;
//                    } else if (dist1 < dist2) {
//                        cmp = NSOrderedAscending;
//                    }
//                }
//            }
//        }
//        return cmp;
//    }];
//    
//    if (self.shouldAllowCurrentPosition) {
//        [r insertObject:@{
//                          @"name" : CURRENT_POSITION_STRING,
//                          @"address" : CURRENT_POSITION_STRING,
//                          @"1Date" : [NSDate date],
//                          @"endDate" : [NSDate date],
//                          @"lat" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.latitude],
//                          @"long" : [NSNumber numberWithDouble:[SMLocationManager instance].lastValidLocation.coordinate.longitude],
//                          @"source" : @"currentPosition",
//                          } atIndex:0];
//    }
//    
//    
//    self.searchResults = r;
//    [self.tableView reloadData];
//    [self.loaderView setAlpha:0.0f];
//}
//
//#pragma mark - osrm request delegate
//
//- (void)request:(SMRequestOSRM *)req finishedWithResult:(id)res {
//    if ([req.requestIdentifier isEqualToString:@"getNearestForPinDrop"]) {
//        NSDictionary * r = res;
//        CLLocation * coord;
//        if ([r objectForKey:@"mapped_coordinate"] && [[r objectForKey:@"mapped_coordinate"] isKindOfClass:[NSArray class]] && ([[r objectForKey:@"mapped_coordinate"] count] > 1)) {
//            coord = [[CLLocation alloc] initWithLatitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:0] doubleValue] longitude:[[[r objectForKey:@"mapped_coordinate"] objectAtIndex:1] doubleValue]];
//        } else {
//            coord = req.coord;
//        }
//        SMNearbyPlaces * np = [[SMNearbyPlaces alloc] initWithDelegate:self];
//        [np findPlacesForLocation:[[CLLocation alloc] initWithLatitude:coord.coordinate.latitude longitude:coord.coordinate.longitude]];
//    }
//}
//
//- (void)request:(SMRequestOSRM *)req failedWithError:(NSError *)error {
//}
//
//- (void)serverNotReachable {
//    SMNetworkErrorView * v = [SMNetworkErrorView getFromNib];
//    CGRect frame = v.frame;
//    frame.origin.x = roundf((self.view.frame.size.width - v.frame.size.width) / 2.0f);
//    frame.origin.y = roundf((self.view.frame.size.height - v.frame.size.height) / 2.0f);
//    [v setFrame: frame];
//    [v setAlpha:0.0f];
//    [self.view addSubview:v];
//    [UIView animateWithDuration:ERROR_FADE animations:^{
//        v.alpha = 1.0f;
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:ERROR_FADE delay:ERROR_WAIT options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//            v.alpha = 0.0f;
//        } completion:^(BOOL finished) {
//            [v removeFromSuperview];
//        }];
//    }];
//}
//
//
//#pragma mark - nearby places delegate
//
//- (void) nearbyPlaces:(SMNearbyPlaces *)owner foundLocations:(NSArray *)locations {
//    NSMutableArray * arr = [NSMutableArray array];
//    if ([[owner.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
//        [arr addObject:[owner.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
//    }
//    if ([[owner.subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] == NO) {
//        [arr addObject:[owner.subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
//    }
//    NSString * s = [arr componentsJoinedByString:@", "];
//    [self setLocationData:@{
//                            @"name" : CURRENT_POSITION_STRING,
//                            @"address" : ([s isEqualToString:@""]?CURRENT_POSITION_STRING:s),
//                            @"location" : owner.coord,
//                            @"source" : @"currentPosition",
//                            @"subsource" : @""
//                            }];
//    if (self.delegate) {
//        [self.delegate locationFound:self.locationData];
//    }
//    [self dismiss];
//}


#pragma mark - UIStatusBarStyle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


@end
