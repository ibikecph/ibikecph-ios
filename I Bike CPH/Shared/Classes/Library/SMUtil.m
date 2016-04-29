//
//  SMUtil.m
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "NSString+Relevance.h"
#import "SMAppDelegate.h"
#import "SMUtil.h"
#import <math.h>

@implementation SMUtil

+ (NSMutableArray *)getFavorites
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                                             stringByAppendingPathComponent:@"favorites.plist"]]) {
        NSArray *arr = [NSArray arrayWithContentsOfFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                                                            stringByAppendingPathComponent:@"favorites.plist"]];
        NSMutableArray *arr2 = [NSMutableArray array];
        if (arr) {
            for (NSDictionary *d in arr) {
                [arr2 addObject:@{
                    @"name" : [d objectForKey:@"name"],
                    @"address" : [d objectForKey:@"address"],
                    @"startDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"startDate"]],
                    @"endDate" : [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"endDate"]],
                    @"source" : [d objectForKey:@"source"],
                    @"subsource" : [d objectForKey:@"subsource"],
                    @"lat" : [d objectForKey:@"lat"],
                    @"long" : [d objectForKey:@"long"],
                    @"order" : @0
                }];
            }
            return arr2;
        }
    }
    return [NSMutableArray array];
}

+ (BOOL)saveFavorites:(NSArray *)fav
{
    NSMutableArray *r = [NSMutableArray array];
    for (NSDictionary *d in fav) {
        [r addObject:@{
            @"name" : [d objectForKey:@"name"],
            @"address" : [d objectForKey:@"address"],
            @"startDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"startDate"]],
            @"endDate" : [NSKeyedArchiver archivedDataWithRootObject:[d objectForKey:@"endDate"]],
            @"source" : [d objectForKey:@"source"],
            @"subsource" : [d objectForKey:@"subsource"],
            @"lat" : [d objectForKey:@"lat"],
            @"long" : [d objectForKey:@"long"]
        }];
    }
    return [r writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]
                              stringByAppendingPathComponent:@"favorites.plist"]
               atomically:YES];
}

+ (BOOL)saveToFavorites:(NSDictionary *)dict
{
    NSMutableArray *arr = [NSMutableArray array];
    NSMutableArray *a = [self getFavorites];
    for (NSDictionary *srch in a) {
        if ([[srch objectForKey:@"name"] isEqualToString:[dict objectForKey:@"name"]] == NO) {
            [arr addObject:srch];
        }
    }
    [arr addObject:dict];

    return [SMUtil saveFavorites:arr];
}

+ (BOOL)isEmailValid:(NSString *)email
{
    NSString *emailRegEx = @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
                           @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
                           @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
                           @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
                           @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
                           @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
                           @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *regExPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    return [regExPredicate evaluateWithObject:[email lowercaseString]];
}

+ (eRegistrationValidationResult)validateRegistrationName:(NSString *)name
                                                    Email:(NSString *)email
                                                 Password:(NSString *)pass
                                      AndRepeatedPassword:(NSString *)repPass
                                                userTerms:(BOOL)userTerms
{
    if (!name || name.length == 0 || !email || email.length == 0 || !pass || pass.length == 0 || !repPass || repPass.length == 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized
                                                     message:@"register_error_fields".localized
                                                    delegate:nil
                                           cancelButtonTitle:@"OK".localized
                                           otherButtonTitles:nil];
        [av show];
        return RVR_EMPTY_FIELDS;
    }

    if (![SMUtil isEmailValid:email]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized
                                                     message:@"register_error_invalid_email".localized
                                                    delegate:nil
                                           cancelButtonTitle:@"OK".localized
                                           otherButtonTitles:nil];
        [av show];
        return RVR_INVALID_EMAIL;
    }

    if (pass.length < MINIMUM_PASS_LENGTH) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized
                                                     message:@"register_error_passwords_short".localized
                                                    delegate:nil
                                           cancelButtonTitle:@"OK".localized
                                           otherButtonTitles:nil];
        [av show];
        return RVR_PASSWORD_TOO_SHORT;
    }

    if ([pass isEqualToString:repPass] == NO) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized
                                                     message:@"register_error_passwords".localized
                                                    delegate:nil
                                           cancelButtonTitle:@"OK".localized
                                           otherButtonTitles:nil];
        [av show];
        return RVR_PASSWORDS_DOESNT_MATCH;
    }

    if (!userTerms) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error".localized
                                                     message:@"register_error_user_terms".localized
                                                    delegate:nil
                                           cancelButtonTitle:@"OK".localized
                                           otherButtonTitles:nil];
        [av show];
        return RVR_USER_TERMS_NOT_ACCEPTED;
    }

    return RVR_REGISTRATION_DATA_VALID;
}

@end