//
//  SMAppDelegate.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 22/01/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAppDelegate.h"
#import "SMSearchHistory.h"
#import "SMUtil.h"

#import "SharedImport.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#if defined(CYKEL_PLANEN)
#import "SMReminder.h"
#endif

@interface SMAppDelegate ()<SMSearchHistoryDelegate>
@end

@implementation SMAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if defined(CYKEL_PLANEN)
    // Reminders has been deprecated. Clear no make sure notifications doesn't fly around and spook the users.
    [SMReminder clear];
#endif
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];

    self.pastRoutes = @[];
    self.currentContacts = @[];
    self.currentEvents = @[];
    self.searchHistory = [SMSearchHistory getSearchHistory];

    // Initialize location manager (not used for map, but for getting current location)
    [SMLocationManager sharedInstance];

    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                                                 .firstObject stringByAppendingPathComponent:@"settings.plist"]] == NO) {
        NSDictionary *d = @{ @"introSeen" : @NO, @"permanentTileCache" : @NO };
        [d writeToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                               .firstObject stringByAppendingPathComponent:@"settings.plist"]
             atomically:NO];
    }

    [self loadSettings];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:@"appLanguage"]) {
        NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
        if ([languages.firstObject isEqualToString:@"da"] || [languages.firstObject isEqualToString:@"dan"]) {
            [defaults setObject:@"dk" forKey:@"appLanguage"];
        }
        else {
            [defaults setObject:@"en" forKey:@"appLanguage"];
        }
        [defaults synchronize];
    }

    [Styler setupAppearance];
    self.window.tintColor = [Styler tintColor];

    // Initialize Realm DB
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = REALM_SCHEMA_VERSION;
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) { };

#warning This block of code will delete the existing Realm DB if the REALM_SCHEMA_VERSION is higher than the existing DB's. When Realm is put into use again please take steps to use it properly, update the Realm pod version and possibly start using RealmSwift.
    NSError *error = NULL;
    uint64_t currentSchemaVersion = [RLMRealm schemaVersionAtURL:config.fileURL encryptionKey:nil error:&error];
    if (currentSchemaVersion == RLMNotVersioned) {
        // New Realm DB, do nothing
    } else if (currentSchemaVersion < config.schemaVersion) {
        // Delete obsolete Realm DB
        NSLog(@"Will delete old Realm DB");
        [[NSFileManager defaultManager] removeItemAtURL:config.fileURL error:&error];
        if (error) {
            NSLog(@"Realm deletion error: %@", error);
        }
    } else if (error) {
        NSLog(@"Realm schema retrieval error: %@", error);
    }
    
    [RLMRealmConfiguration setDefaultConfiguration:config];
    [RLMRealm defaultRealm];
    //[RLMRealm compress:true]; Temporarily disabled

#if TRACKING_ENABLED
    [TrackingHandler sharedInstance];
#else
    [NonTrackingHandler sharedInstance];
#endif

    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return UIInterfaceOrientationMaskPortrait;
}
    
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    BOOL handled = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                               annotation:options[UIApplicationOpenURLOptionsAnnotationKey]
                    ];
    
    // Add any custom logic here.
    
    return handled;
}

- (BOOL)saveSettings
{
    NSString *s = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
        stringByAppendingPathComponent:@"settings.plist"];
    return [self.appSettings writeToFile:s atomically:NO];
}

- (void)loadSettings
{
    NSMutableDictionary *d = [NSMutableDictionary
        dictionaryWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                         stringByAppendingPathComponent:@"settings.plist"]];
    self.appSettings = d;
}

- (void)clearSettings
{
    self.appSettings = [NSMutableDictionary new];
    [self saveSettings];
}

#pragma mark - Search History Delegate

- (void)searchHistoryOperationFinishedSuccessfully:(id)req withData:(id)data
{
    // TODO: make changes after Jacob fixes it on his end

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'z"];
    NSArray *arr = [data objectForKey:@"data"];
    NSMutableArray *arr2 = [NSMutableArray array];
    if (arr && [arr isKindOfClass:[NSArray class]]) {
        for (NSDictionary *d in arr) {
            NSDate *sd = [df dateFromString:[d objectForKey:@"startDate"]];
            if (sd == nil) {
                sd = [NSDate date];
            }
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[d[@"toLattitude"] doubleValue] longitude:[d[@"toLongitude"] doubleValue]];
            HistoryItem *item =
                [[HistoryItem alloc] initWithName:d[@"toName"] address:d[@"toName"] location:location startDate:sd endDate:[NSDate date]];

            [arr2 addObject:item];
            NSLog(@"%@", data);
            NSLog(@"%@", item);
        }
        [arr2 sortUsingComparator:^NSComparisonResult(HistoryItem *obj1, HistoryItem *obj2) {
          NSDate *d1 = obj1.startDate;
          NSDate *d2 = obj2.startDate;
          return [d2 compare:d1];
        }];
        [self setSearchHistory:arr2];
    }

    [SMSearchHistory saveSearchHistory];
}

@end
