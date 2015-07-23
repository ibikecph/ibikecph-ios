//
//  SMAppDelegate.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GAITracker;
#if defined(CYKEL_PLANEN)
#import "SMMapOverlays.h"
#endif

/**
 * App delegate. Handles facebook session, contacts, events, routes history, search history, Google Analytics trakcing, and app settings.
 */
@interface SMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) NSArray * currentContacts;
@property (nonatomic, strong) NSArray * currentEvents;
@property (nonatomic, strong) NSArray * pastRoutes;
@property (nonatomic, strong) NSArray * searchHistory;

@property(nonatomic, strong) id<GAITracker> tracker;

#if defined(CYKEL_PLANEN)
@property (nonatomic, strong) SMMapOverlays *mapOverlays;
#endif

@property (nonatomic, strong) NSMutableDictionary * appSettings;
- (BOOL)saveSettings;
- (void)loadSettings;
- (void)clearSettings;

@end
