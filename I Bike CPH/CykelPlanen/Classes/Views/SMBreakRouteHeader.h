//
//  SMBreakRouteHeader.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/16/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell that acts as break route header. Has title label, and route distance label. Used in SMBreakRouteViewController
 */
@interface SMBreakRouteHeader : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *routeDistance;
@end
