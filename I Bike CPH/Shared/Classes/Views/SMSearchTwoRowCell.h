//
//  SMEnterRouteTwoRowCell.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 20/03/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMSearchCell.h"

/**
 * Table view cell extending SMSearchCell w/ address label. Used in SMSearchController.
 */
@interface SMSearchTwoRowCell : SMSearchCell

@property (weak, nonatomic) IBOutlet TTTAttributedLabel *addressLabel;

@end
