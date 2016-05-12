//
//  SMBreakRouteViewController.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

#if defined(CYKEL_PLANEN)
#import "SMAddressPickerView.h"
#import "SMStationPickerView.h"
#import "SMTripRoute.h"
#endif

/**
 * View controller for breaking a route. Has destination address button, source address button, trip route, full route, source station, destination
 * station, source name, destination name, source address, destinaton address
 */
@interface SMBreakRouteViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, SMBreakRouteDelegate,
                                                         AddressSelectDelegate, UIAlertViewDelegate>

@property(weak, nonatomic) IBOutlet UITableView *tableView;

#if defined(CYKEL_PLANEN)
@property(nonatomic, strong) SMTripRoute *tripRoute;
@property(nonatomic, strong) SMRoute *fullRoute;
@property(nonatomic, strong) SMStationInfo *sourceStation;
@property(nonatomic, strong) SMStationInfo *destinationStation;

@property(nonatomic, strong) NSString *sourceName;
@property(nonatomic, strong) NSString *destinationName;

@property(nonatomic, strong) NSString *sourceAddress;
@property(nonatomic, strong) NSString *destinationAddress;
#endif

@end