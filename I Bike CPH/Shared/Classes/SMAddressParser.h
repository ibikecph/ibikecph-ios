//
//  SMAddressParser.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 12/11/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * \ingroup libs
 * Address parser
 */

@class UnknownSearchListItem;

@interface SMAddressParser : NSObject

/**
 * Parses addressString and splits it into street, number, zip, city
 */
+ (UnknownSearchListItem *)parseAddress:(NSString *)addressString;


@end
