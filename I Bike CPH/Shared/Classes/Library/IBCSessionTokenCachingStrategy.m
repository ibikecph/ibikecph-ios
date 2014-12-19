//
//  IBCSessionTokenCachingStrategy.m
//  I Bike CPH
//
//  Created by Tobias Due Munk on 18/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#import "IBCSessionTokenCachingStrategy.h"


@interface IBCSessionTokenCachingStrategy()

@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSArray *permissions;

@end

@implementation IBCSessionTokenCachingStrategy

- (instancetype)initWithToken:(NSString *)token andPermissions:(NSArray *)permissions {
 
    self = [super init];
    if (self) {
        self.token = token;
        self.permissions = permissions;
    }
    return self;
}

- (FBAccessTokenData *)fetchFBAccessTokenData
{
    NSMutableDictionary *tokenInformationDictionary = [NSMutableDictionary new];
    
    // Expiration date
    tokenInformationDictionary[@"com.facebook.sdk:TokenInformationExpirationDateKey"] = [NSDate dateWithTimeIntervalSinceNow: 3600];
    
    // Refresh date
    tokenInformationDictionary[@"com.facebook.sdk:TokenInformationRefreshDateKey"] = [NSDate date];
    
    // Token key
    tokenInformationDictionary[@"com.facebook.sdk:TokenInformationTokenKey"] = self.token;
    
    // Permissions
    tokenInformationDictionary[@"com.facebook.sdk:TokenInformationPermissionsKey"] = self.permissions;
    
    // Login key
    tokenInformationDictionary[@"com.facebook.sdk:TokenInformationLoginTypeLoginKey"] = @0;
    
    return [FBAccessTokenData createTokenFromDictionary: tokenInformationDictionary];
}

@end
