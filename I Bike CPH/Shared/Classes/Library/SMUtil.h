//
//  SMUtil.h
//  I Bike CPH
//
//  Created by Petra Markovic on 1/31/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _registrationValidationResult {
    RVR_REGISTRATION_DATA_VALID,
    RVR_EMPTY_FIELDS,
    RVR_INVALID_EMAIL,
    RVR_PASSWORD_TOO_SHORT,
    RVR_PASSWORDS_DOESNT_MATCH,
    RVR_USER_TERMS_NOT_ACCEPTED

} eRegistrationValidationResult;

@protocol ViewTapDelegate<NSObject>
- (void)viewTapped:(id)view;
@end

/**
 * Various utils, e.g. email validation
 */

@interface SMUtil : NSObject

/**
 * check if email is valid
 */
+ (BOOL)isEmailValid:(NSString *)email;
/**
 * registration validation
 */
+ (eRegistrationValidationResult)validateRegistrationName:(NSString *)name
                                                    Email:(NSString *)email
                                                 Password:(NSString *)pass
                                      AndRepeatedPassword:(NSString *)repPass
                                                userTerms:(BOOL)userTerms;

@end
