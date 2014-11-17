//
//  SMRouteInfoViewController.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/2/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMSingleRouteInfo.h"

/**
 * View controller for route information. Has title label, and single route information.
 */
@interface SMRouteInfoViewController : UIViewController<UITableViewDataSource, UITableViewDataSource, NSXMLParserDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) SMSingleRouteInfo* singleRouteInfo;
@end
