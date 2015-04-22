//
//  SMDirectionTopCell.h
//  I Bike CPH
//
//  Created by Petra Markovic on 2/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SMTurnInstruction.h"

/**
 * View for turn instructions.
 */
@interface SMDirectionTopCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgDirection;
@property (weak, nonatomic) IBOutlet UILabel *lblDistance;
@property (weak, nonatomic) IBOutlet UILabel *lblWayname;

@property NSInteger position;

- (void)renderViewFromInstruction:(SMTurnInstruction *)turn;

@end
