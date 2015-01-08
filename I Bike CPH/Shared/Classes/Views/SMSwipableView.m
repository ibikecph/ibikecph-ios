//
//  SMSwipableView.m
//  iBike
//
//  Created by Ivan Pavlovic on 27/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMSwipableView.h"
#import "SMUtil.h"

@implementation SMSwipableView

+ (SMSwipableView*) getFromNib {
    SMSwipableView * xx = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"SMSwipableView" owner:nil options:nil];
    for(id currentObject in topLevelObjects) {
        if([currentObject isKindOfClass:[SMSwipableView class]]) {
            xx = (SMSwipableView *)currentObject;
            break;
        }
    }
    return xx;
}


- (void)renderViewFromInstruction:(SMTurnInstruction *)turn {
    self.lblWayname.text = turn.wayName;
    self.lblDistance.text = formatDistance(turn.lengthInMeters); // dynamic distance
    self.imgDirection.image = turn.directionIcon;
}


@end
