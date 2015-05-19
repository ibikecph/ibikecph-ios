//
//  SMAppDelegate.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMUtil.h"
#import "SMSearchHistory.h"

@interface SMAppDelegate () <SMSearchHistoryDelegate>
@end

@implementation SMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.pastRoutes = @[];
    self.currentContacts = @[];
    self.currentEvents = @[];
    self.searchHistory = [SMSearchHistory getSearchHistory];
    
//    [[Settings sharedInstance] clear];
    
    /**
     * initialize Google Analytics
     */
    [GAI sharedInstance].dispatchInterval = GOOGLE_ANALYTICS_DISPATCH_INTERVAL;
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLE_ANALYTICS_KEY];
    [GAI sharedInstance].defaultTracker = self.tracker;
    [[GAI sharedInstance].defaultTracker set:kGAISampleRate value:GOOGLE_ANALYTICS_SAMPLE_RATE];
    [[GAI sharedInstance].defaultTracker set:kGAIAnonymizeIp value:GOOGLE_ANALYTICS_ANONYMIZE];

    [[GAI sharedInstance].defaultTracker set:kGAIScreenName value:@""];
    [[GAI sharedInstance].defaultTracker send:[[GAIDictionaryBuilder createScreenView]  build]];


    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"settings.plist"]] == NO) {
        NSDictionary * d = @{
                             @"introSeen" : @NO,
                             @"permanentTileCache" : @NO
                             };
        [d writeToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"settings.plist"] atomically:NO];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"routeme.plist"]] == NO) {
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"routeme" ofType:@"plist"] toPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"routeme.plist"] error:nil];
    }
    
    [self loadSettings];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:@"appLanguage"]) {
        /**
         * init default settings
         */
        NSArray* languages = [defaults objectForKey:@"AppleLanguages"];
        if ([languages.firstObject isEqualToString:@"da"] || [languages.firstObject isEqualToString:@"dan"]) {
            [defaults setObject:@"dk" forKey:@"appLanguage"];
        } else {
            [defaults setObject:@"en" forKey:@"appLanguage"];
        }
        [defaults synchronize];
    }
    
    [Styler setupAppearance];
    self.window.tintColor = [Styler tintColor];
    
//    [RLMRealm deleteDefaultRealmFile];

    // Auto migrate Realm
    [RLMRealm setSchemaVersion:6 forRealmAtPath:[RLMRealm defaultRealmPath] withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {
        if (oldSchemaVersion < 1) {
//            [migration enumerateObjects:Track.className
//                                  block:^(RLMObject *oldObject, RLMObject *newObject) {
//                                      
//                                      // combine name fields into a single field
//                                      newObject[@"activity"] = [Track hello];
//                                  }];
        }
    }];
    [RLMRealm migrateRealmAtPath:[RLMRealm defaultRealmPath]];
    
    [TrackingHandler sharedInstance];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)saveSettings {
    NSString * s = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"settings.plist"];
    return [self.appSettings writeToFile:s atomically:NO];
}

- (void)loadSettings {
    NSMutableDictionary * d = [NSMutableDictionary dictionaryWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"settings.plist"]];
    self.appSettings = d;
}

#pragma mark - search history delegate

- (void)searchHistoryOperationFinishedSuccessfully:(id)req withData:(id)data {
    
//TODO: make changes after Jacob fixes it on his end
    
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'z"];
    NSArray * arr = [data objectForKey:@"data"];
    NSMutableArray * arr2 = [NSMutableArray array];
    if (arr && [arr isKindOfClass:[NSArray class]]) {
        for (NSDictionary * d in arr) {
            NSDate * sd = [df dateFromString:[d objectForKey:@"startDate"]];
            if (sd == nil) {
                sd = [NSDate date];
            }
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[d[@"toLattitude"] doubleValue] longitude:[d[@"toLongitude"] doubleValue]];
            HistoryItem *item = [[HistoryItem alloc] initWithName:d[@"toName"] address:d[@"toName"] location:location startDate:sd endDate:[NSDate date]];
            
            [arr2 addObject:item];
            NSLog(@"%@", data);
            NSLog(@"%@", item);
        }
        [arr2 sortUsingComparator:^NSComparisonResult(HistoryItem *obj1, HistoryItem* obj2) {
            NSDate * d1 = obj1.startDate;
            NSDate * d2 = obj2.startDate;
            return [d2 compare:d1];
        }];
        [self setSearchHistory:arr2];
    }
    
    [SMSearchHistory saveSearchHistory];
}

@end
