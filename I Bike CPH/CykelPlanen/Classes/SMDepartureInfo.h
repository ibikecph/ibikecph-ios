//
//  SMDepartureInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMTime.h"

@interface SMDepartureInfo : NSObject

@property(strong, nonatomic) SMTime* dayStart;
@property(strong, nonatomic) SMTime* dayEnd;
@property(strong, nonatomic) SMTime* nightStart;
@property(strong, nonatomic) SMTime* nightEnd;
@end
