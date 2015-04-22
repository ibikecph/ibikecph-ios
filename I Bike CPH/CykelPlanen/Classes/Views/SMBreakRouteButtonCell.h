//
//  SMBreakRouteButtonCell.h
//  I Bike CPH
//
//  Created by Igor Jerković on 7/16/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Table view cell. Has break route button. Used in SMBreakRouteViewController.
 */
@interface SMBreakRouteButtonCell : UITableViewCell
@property (weak, nonatomic) IBOutlet SMPatternedButton *btnBreakRoute;
@end
