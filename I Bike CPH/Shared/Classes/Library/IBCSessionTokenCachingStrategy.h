//
//  IBCSessionTokenCachingStrategy.h
//  I Bike CPH
//
//  Created by Tobias Due Munk on 18/12/14.
//  Copyright (c) 2014 I Bike CPH. All rights reserved.
//

#import "FBSessionTokenCachingStrategy.h"

@interface IBCSessionTokenCachingStrategy : FBSessionTokenCachingStrategy

- (instancetype)initWithToken:(NSString *)token andPermissions:(NSArray *)permissions;

@end
