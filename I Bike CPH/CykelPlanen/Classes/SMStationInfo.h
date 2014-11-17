//
//  SMRouteStationInfo.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
    SMStationInfoTypeUndefined = 0,
    SMStationInfoTypeTrain = 1,
    SMStationInfoTypeMetro = 2,
    SMStationInfoTypeService = 3,

    SMStationInfoTypeLocalTrain= 4

} SMStationInfoType;

/**
 * Station information. Has coordinate, name, and type. Used in SMArrivalInfo and more.
 */
@interface SMStationInfo : NSObject<NSCoding>

+(NSString*)imageNameForType:(SMStationInfoType)type;
-(id)initWithCoordinate:(CLLocationCoordinate2D)coord;
-(id)initWithLongitude:(double)lon latitude:(double)lat;
-(id)initWithLongitude:(double)lon latitude:(double)lat name:(NSString*)name;
-(id)initWithLongitude:(double)lon latitude:(double)lat name:(NSString*)name type:(SMStationInfoType)type;

@property(nonatomic, strong) CLLocation* location;
@property(nonatomic, assign, readonly) double longitude;
@property(nonatomic, assign, readonly) double latitude;
@property(nonatomic, strong) NSString* name;
@property(nonatomic, assign) SMStationInfoType type;

-(BOOL)isValid;
@end
