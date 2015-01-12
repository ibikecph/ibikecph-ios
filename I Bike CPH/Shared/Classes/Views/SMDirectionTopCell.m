//
//  SMDirectionTopCell.m
//  I Bike CPH
//
//  Created by Petra Markovic on 2/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMDirectionTopCell.h"

#import "SMUtil.h"

@implementation SMDirectionTopCell

- (void)renderViewFromInstruction:(SMTurnInstruction *)turn {
    if ([turn.shortDescriptionString rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
        [self.lblWayname setText:translateString(turn.shortDescriptionString)];
    } else {
        [self.lblWayname setText:turn.shortDescriptionString];
    }
    
    [self.lblDistance setText:formatDistance(turn.lengthInMeters)]; // dynamic distance
    self.imgDirection.image = turn.directionIcon;
}



@end
