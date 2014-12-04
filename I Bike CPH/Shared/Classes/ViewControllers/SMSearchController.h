//
//  SMSearchController.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 14/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTranslatedViewController.h"
#import "SMAutocomplete.h"
#import "SMRequestOSRM.h"
#import "SMNearbyPlaces.h"
#import "SMAPIOperation.h"

@protocol SMSearchDelegate <NSObject>

- (void)locationFound:(NSObject<SearchListItem>*)locationItem;

@end

/**
 * View controller to search for address. Has search field, and results list. FIXME: Merge.
 */
@interface SMSearchController : SMTranslatedViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SMAutocompleteDelegate, SMAPIOperationDelegate, SMRequestOSRMDelegate, SMNearbyPlacesDelegate>

@property (nonatomic, strong) NSString * searchText;
@property (nonatomic, weak) id<SMSearchDelegate> delegate;
@property BOOL shouldAllowCurrentPosition;
@property (nonatomic, strong) NSObject<SearchListItem> *locationItem;

@end
