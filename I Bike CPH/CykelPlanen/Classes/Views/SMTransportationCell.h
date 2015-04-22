//
//  SMTransportationCell.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell for transportation selection. Has source address button, destination address button, address information button, source activity indicator, destination activity indicator, source station icon, destination station icon. Used in SMBreakRouteViewController.
 */
@interface SMTransportationCell : UITableViewCell

@property(weak, nonatomic) IBOutlet UIButton* buttonAddressSource;
@property(weak, nonatomic) IBOutlet UIButton* buttonAddressDestination;
@property(weak, nonatomic) IBOutlet UIButton* buttonAddressInfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sourceActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *destinationActivityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *sourceStationIcon;
@property (weak, nonatomic) IBOutlet UIImageView *destStationIcon;
@end
