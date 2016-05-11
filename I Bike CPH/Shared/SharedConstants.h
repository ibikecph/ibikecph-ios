//
//  SharedConstants.h
//  I Bike CPH
//
//  Created by Tobias Due Munk on 24/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

#ifndef I_Bike_CPH_SharedConstants_h
#define I_Bike_CPH_SharedConstants_h

#define REACHABILITY_CHECK_HOSTNAME @"www.ibikecph.dk"

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

#define GOOGLE_ANALYTICS_DISPATCH_INTERVAL 120
#define GOOGLE_ANALYTICS_SAMPLE_RATE @"100"
#define GOOGLE_ANALYTICS_SESSION_TIMEOUT 1800
#define GOOGLE_ANALYTICS_ANONYMIZE @"YES"

#define ZOOM_TO_TURN_DURATION 4 // in seconds
#define DEFAULT_MAP_ZOOM 15.0
#define DEFAULT_TURN_ZOOM 15.0
#define MAX_MAP_ZOOM 17.0
#define PATH_OPACITY 0.8f

#define BUILD_STRING [NSString stringWithFormat:@"%@: %@", translateString(@"Build"), BUILD_VERSION]

#define MAX_TURNS 4

#define MIN_DISTANCE_FOR_RECALCULATION 20.0
#define MAX_DISTANCE_FOR_PUBLIC_TRANSPORT 300.0

#define API_DEFAULT_ACCEPT @{@"key": @"Accept", @"value" : @"application/vnd.ibikecph.v1"}
#define API_DEFAULT_ACCEPT2 @{@"key": @"value"}
#define API_USER_AGENT @{@"key": @"User-Agent", @"value" : USER_AGENT}
#define API_DEFAULT_HEADERS @[API_DEFAULT_ACCEPT, API_USER_AGENT, @{@"key": @"Content-Type", @"value" : @"application/json"}]

#define API_LOCALE @{@"service" : @"settings", @"transferMethod" : @"GET", @"headers" : API_DEFAULT_HEADERS}

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

#define REALM_SCHEMA_VERSION 12

#define TRACKING_ENABLED 0

#endif
