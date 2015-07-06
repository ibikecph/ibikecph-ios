//
//  SharedImport.h
//  I Bike CPH
//
//  Created by Tobias Due Munk on 10/11/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

//#ifndef I_Bike_CPH_SharedImport_h
//#define I_Bike_CPH_SharedImport_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SMMapOverlays.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "SMAddressParser.h"
#import "SMAnalytics.h"
@import CoreLocation;

#if defined(I_BIKE_CPH)
    #import "I_Bike_CPH-Swift.h"
#elif defined(CYKEL_PLANEN)
    #import "CykelPlanen-Swift.h"
#else
    #error Must define a target (I_BIKE_CPH / CYKEL_PLANEN) macro!
#endif

#import "AsyncImageView.h"
#import "SMTranslation.h"
#import "NSString+URLEncode.h"
#import "SMCustomCheckbox.h"
#import "keys.h"
#import "SMTranslatedViewController.h"
#import "SMUtil.h"
#import "SMCustomButton.h"
#import "SMPatternedButton.h"
#import "SMNetworkErrorView.h"

#import "SharedConstants.h"

#if DISTRIBUTION_VERSION
    #define debugLog(args...)    // NO logs
#else
    #define debugLog(args...)    NSLog(@"%@", [NSString stringWithFormat: args])
#endif

#import "SMRouteConsts.h"
#import "SMRouteUtils.h"

//#endif
