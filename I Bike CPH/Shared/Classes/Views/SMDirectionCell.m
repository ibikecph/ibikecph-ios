//
//  SMDirectionCell.m
//  I Bike CPH
//
//  Created by Petra Markovic on 2/1/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMDirectionCell.h"

#import "SMUtil.h"

@interface SMDirectionCell ()

@end

@implementation SMDirectionCell

- (void)renderViewFromInstruction:(SMTurnInstruction *)turn {
    if ([turn.shortDescriptionString rangeOfString:@"\\{.+\\:.+\\}" options:NSRegularExpressionSearch].location != NSNotFound) {
        [self.lblWayname setText:turn.shortDescriptionString.localized];
    } else {
        NSString* value=turn.shortDescriptionString;
        if([value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length==0){
            value= @"direction_15".localized;
        }
        [self.lblWayname setText:value];
    }
    [self.lblDistance setText:formatDistance(turn.lengthInMeters)]; // dynamic distance
    self.imgDirection.image = turn.directionIcon;
}

@end
