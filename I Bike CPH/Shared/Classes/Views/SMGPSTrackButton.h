//
//  SMGPSTrackButton.h
//  iBike
//
//  Created by Petra Markovic on 2/25/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SMGPSTrackButtonStateFollowing,
    SMGPSTrackButtonStateFollowingWithHeading,
    SMGPSTrackButtonStateNotFollowing
} ButtonStateType;

/**
 * Button to control GPS tracking. Has three track states i.e. following, following w/ header, and not following.
 */
@interface SMGPSTrackButton : UIButton

@property (nonatomic,readonly) ButtonStateType gpsTrackState;
@property (nonatomic, readonly) ButtonStateType prevGpsTrackState;

- (void)newGpsTrackState:(ButtonStateType)gpsTrackState;

@end
