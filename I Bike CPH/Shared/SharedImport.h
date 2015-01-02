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

#define API_ADDRESS @"www.ibikecph.dk"
//#define API_SERVER @"http://ibikecph-staging.herokuapp.com/api"
#define API_SERVER @"https://www.ibikecph.dk/api"

#define translateString(txt) [SMTranslation decodeString:(txt)]

#define CURRENT_POSITION_STRING [SMTranslation decodeString:@"current_position"]

#define ORG_NAME @"ibikecph"

#define ERROR_FADE 0.2f
#define ERROR_WAIT 2.0f

#define CALENDAR_MAX_DAYS 15

#define DEFAULT_LANGUAGE @"en"


#define DIRECTION_FONT_SIZE 17.0f
#define WAYPOINT_FONT_SIZE 20.0f
#define INSTRUCTIONS_LABEL_WIDTH 194.0f

#define MAX_HEIGHT_FOR_EVENTS_TABLE 170.0f
#define MAIL_RECIPIENTS @[@"support+00c86bd0c75940dcb863bbca9fa33313@feedback.hockeyapp.net", @"emil.tin@tmf.kk.dk"]
#define ZOOM_TO_TURN_DURATION 4 // in seconds
#define DEFAULT_MAP_ZOOM 18.5
#define DEFAULT_TURN_ZOOM 18.5
#define MAX_MAP_ZOOM 20
#define PATH_COLOR [UIColor colorWithRed:6.0f/255.0f green:63.0f/255.0f blue:114.0f/255.0f alpha:0.85f]
#define PATH_OPACITY 0.8f

#define GOOGLE_ANALYTICS_DISPATCH_INTERVAL 120
#define GOOGLE_ANALYTICS_SAMPLE_RATE @"100"
#define GOOGLE_ANALYTICS_SESSION_TIMEOUT 1800
#define GOOGLE_ANALYTICS_ANONYMIZE @"YES"

#if DISTRIBUTION_VERSION
#define debugLog(args...)    // NO logs
#else
#define debugLog(args...)    NSLog(@"%@", [NSString stringWithFormat: args])
#endif

#define BUILD_STRING [NSString stringWithFormat:@"%@: %@", translateString(@"Build"), BUILD_VERSION]

#define MAX_TURNS 4

#define MIN_DISTANCE_FOR_RECALCULATION 20.0

#define API_LOGIN @{@"service" : @"login", @"transferMethod" : @"POST", @"headers" : API_DEFAULT_HEADERS}
#define API_REGISTER @{@"service" : @"users", @"transferMethod" : @"POST",  @"headers" : API_DEFAULT_HEADERS}
#define API_GET_USER_DATA @{@"service" : @"users", @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS}
#define API_CHANGE_USER_DATA @{@"service" : @"users", @"transferMethod" : @"PUT",  @"headers" : API_DEFAULT_HEADERS}
#define API_CHANGE_PASSWORD @{@"service" : @"users/password", @"transferMethod" : @"PUT",  @"headers" : API_DEFAULT_HEADERS}
#define API_DELETE_USER_DATA @{@"service" : @"users", @"transferMethod" : @"DELETE",  @"headers" : API_DEFAULT_HEADERS}

#define API_SEND_FEEDBACK @{@"service" : @"issues", @"transferMethod" : @"POST",  @"headers" : API_DEFAULT_HEADERS}

#define API_ADD_FAVORITE @{@"service" : @"favourites", @"transferMethod" : @"POST",  @"headers" : API_DEFAULT_HEADERS}
#define API_EDIT_FAVORITE @{@"service" : @"favourites", @"transferMethod" : @"PUT",  @"headers" : API_DEFAULT_HEADERS}
#define API_DELETE_FAVORITE @{@"service" : @"favourites", @"transferMethod" : @"DELETE",  @"headers" : API_DEFAULT_HEADERS}
#define API_LIST_FAVORITES @{@"service" : @"favourites", @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS}

#define API_LIST_HISTORY @{@"service" : @"routes", @"transferMethod" : @"GET",  @"headers" : API_DEFAULT_HEADERS}
#define API_ADD_HISTORY @{@"service" : @"routes", @"transferMethod" : @"POST",  @"headers" : API_DEFAULT_HEADERS}

#define API_SORT_FAVORITES @{@"service" : @"favourites/reorder", @"transferMethod" : @"POST",  @"headers" : API_DEFAULT_HEADERS}

#define kFAVORITES_CHANGED @"favoritesChanged"

#import "SMRouteConsts.h"
#import "SMRouteUtils.h"

//#endif
