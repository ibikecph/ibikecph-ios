//
//  SMAppDelegate.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

@import UIKit;
#import "SMSearchHistory.h"

@protocol GAITracker;

@class Overlays;

@interface SMAppDelegate : UIResponder<UIApplicationDelegate, SMSearchHistoryDelegate>

@property(strong, nonatomic) UIWindow *window;

@property(nonatomic, strong) NSArray *currentContacts;
@property(nonatomic, strong) NSArray *currentEvents;
@property(nonatomic, strong) NSArray *pastRoutes;
@property(nonatomic, strong) NSArray *searchHistory;

@property(nonatomic, strong) id<GAITracker> tracker;

@property (nonatomic, strong) Overlays *mapOverlays;

@property(nonatomic, strong) NSMutableDictionary *appSettings;

- (BOOL)saveSettings;
- (void)loadSettings;
- (void)clearSettings;

@end