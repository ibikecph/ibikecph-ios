//
//  SMBreakRouteViewController.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMTripRoute.h"
#import "SMStationPickerView.h"
#import "SMAddressPickerView.h"
@interface SMBreakRouteViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, SMBreakRouteDelegate, AddressSelectDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView* tableView;

@property (weak, nonatomic) IBOutlet SMPatternedButton *buttonAddressDestination;
@property (weak, nonatomic) IBOutlet SMPatternedButton *buttonAddressSource;
@property(nonatomic, strong) SMTripRoute* tripRoute;
@property(nonatomic, strong) SMRoute* fullRoute;
@property(nonatomic, strong) SMStationInfo* sourceStation;
@property(nonatomic, strong) SMStationInfo* destinationStation;

@property(nonatomic, strong) NSString* sourceName;
@property(nonatomic, strong) NSString* destinationName;

@property(nonatomic, strong) NSString* sourceAddress;
@property(nonatomic, strong) NSString* destinationAddress;

@end
