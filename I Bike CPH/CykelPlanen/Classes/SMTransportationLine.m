//
//  SMTransportationLine.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMNode.h"
#import "SMRouteTimeInfo.h"
#import "SMSingleRouteInfo.h"
#import "SMStationInfo.h"
#import "SMTransportationLine.h"

#define KEY_STATIONS @"KeyStations"
#define KEY_NAME @"KeyName"

@interface SMTransportationLine ()

@end

@implementation SMTransportationLine
- (id)initWithFile:(NSString *)filePath
{
    self = [super init];
    if (self) {
        [self loadFromFile:filePath];
    }
    return self;
}

- (id)initWithRelation:(SMRelation *)pRelation
{
    if (self = [super init]) {
        NSMutableArray *tempStations = [NSMutableArray new];
        for (SMNode *node in pRelation.nodes) {
            SMStationInfo *stationInfo = [[SMStationInfo alloc] initWithCoordinate:node.coordinate];
            [tempStations addObject:stationInfo];
        }

        self.stations = [NSArray arrayWithArray:tempStations];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.stations forKey:KEY_STATIONS];
    [aCoder encodeObject:self.name forKey:KEY_NAME];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _stations = [aDecoder decodeObjectForKey:KEY_STATIONS];
        _name = [aDecoder decodeObjectForKey:KEY_NAME];
    }
    return self;
}

- (void)loadFromFile:(NSString *)filePath
{
    NSError *err;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];

    _name = [dict valueForKey:@"name"];
    NSArray *coord = [dict valueForKey:@"coordinates"];
    NSNumber *lon;
    NSNumber *lat;
    NSMutableArray *stations = [NSMutableArray new];
    for (NSArray *arr in coord) {
        lon = [arr objectAtIndex:0];
        lat = [arr objectAtIndex:1];
        SMStationInfo *stationInfo = [[SMStationInfo alloc] initWithLongitude:lon.doubleValue latitude:lat.doubleValue];

        [stations addObject:stationInfo];
    }
    self.stations = stations;
}

- (SMTransportationLine *)clone
{
    static NSInteger cloneCount = 1;
    SMTransportationLine *line = [[SMTransportationLine alloc] init];
    line.stations = self.stations;
    line.name = [NSString stringWithFormat:@"%@ clone %ld", self.name, (long)cloneCount++];
    return line;
}

- (SMLineData *)weekLineData
{
    if (!_weekLineData) {
        _weekLineData = [SMLineData new];
    }
    return _weekLineData;
}

- (SMLineData *)weekendLineData
{
    if (!_weekendLineData) {
        _weekendLineData = [SMLineData new];
    }
    return _weekendLineData;
}

- (SMLineData *)weekendNightLineData
{
    if (!_weekendNightLineData) {
        _weekendNightLineData = [SMLineData new];
    }
    return _weekendNightLineData;
}

- (BOOL)containsRouteFrom:(SMStationInfo *)sourceStation to:(SMStationInfo *)destStation forTime:(TravelTime)time
{
    BOOL hasSource = NO;
    BOOL hasDestination = NO;

    SMLineData *lineData;
    if (time == TravelTimeWeekDay) {
        lineData = self.weekLineData;
    }
    else if (time == TravelTimeWeekend) {
        lineData = self.weekendLineData;
    }
    else if (time == TravelTimeWeekendNight) {
        lineData = self.weekendNightLineData;
    }

    NSNumber *invalid = @-1;
    for (SMArrivalInfo *arrivalInfo in lineData.arrivalInfos) {
        if (arrivalInfo.station == sourceStation) {
            for (NSNumber *num in arrivalInfo.arrivals) {
                if (![num isEqual:invalid]) {
                    hasSource = YES;
                    break;
                }
            }
            for (NSNumber *num in arrivalInfo.departures) {
                if (![num isEqual:invalid]) {
                    hasSource = YES;
                    break;
                }
            }
        }
        else if (arrivalInfo.station == destStation) {
            for (NSNumber *num in arrivalInfo.arrivals) {
                if (![num isEqual:invalid]) {
                    hasDestination = YES;
                    break;
                }
            }
            for (NSNumber *num in arrivalInfo.departures) {
                if (![num isEqual:invalid]) {
                    hasDestination = YES;
                    break;
                }
            }

            return hasDestination;
        }
    }

    return hasSource && hasDestination;
}

- (NSInteger)differenceFrom:(SMStationInfo *)sourceStation to:(SMStationInfo *)destStation
{
    NSInteger sourceIndex = 0;
    NSInteger destIndex = 0;
    NSInteger index = 0;
    for (SMStationInfo *station in self.stations) {
        if (station == sourceStation) {
            sourceIndex = index;
        }
        else if (station == destStation) {
            destIndex = index;
        }
        index++;
    }

    return labs(sourceIndex - destIndex);
}

- (void)addTimestampsForRouteInfo:(SMSingleRouteInfo *)singleRouteInfo array:(NSMutableArray *)arr currentTime:(NSDate *)date time:(TravelTime)time
{
    NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *weekdayComponents = [cal components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger hour = [weekdayComponents hour];
    NSInteger mins = [weekdayComponents minute];

    SMLineData *lineData;
    if (time == TravelTimeWeekDay) {
        lineData = self.weekLineData;
    }
    else if (time == TravelTimeWeekend) {
        lineData = self.weekendLineData;
    }
    else if (time == TravelTimeWeekendNight) {
        lineData = self.weekendNightLineData;
    }

    BOOL departure = NO;
    if ([self.stations indexOfObject:singleRouteInfo.sourceStation] < [self.stations indexOfObject:singleRouteInfo.destStation]) {
        departure = YES;
    }

    for (SMArrivalInfo *arrivalInfo in lineData.arrivalInfos) {
        if (arrivalInfo.station == singleRouteInfo.sourceStation) {
            NSArray *destArr = (departure) ? arrivalInfo.departures : arrivalInfo.arrivals;
            NSInteger index = -1;
            NSInteger i = 0;
            NSInteger num = 0;

            NSInteger minimumMinute = 61;
            NSInteger indexOfSmallestNumberInArray = 0;

            NSArray *srcArr = (departure) ? arrivalInfo.departures : arrivalInfo.arrivals;

            do {
                num = ((NSNumber *)[srcArr objectAtIndex:i]).intValue;
                if (num < ((NSNumber *)srcArr[indexOfSmallestNumberInArray]).intValue && ![destArr[i] isEqual:@-1]) {
                    // Find the smallest minute in an hour. Used if we don't find a single index. For example it's 11:59 atm. and minutes are [2, 12,
                    // ..., 52].
                    // We wont find a minute that is > 59. Therefore we take the smallest value - and it is 2.
                    indexOfSmallestNumberInArray = i;
                }

                if (num > mins && num < minimumMinute && ![destArr[i] isEqual:@-1]) {
                    minimumMinute = num;
                    index = i;
                }

            } while (++i < srcArr.count);

            if (minimumMinute > 60) {
                index = indexOfSmallestNumberInArray;
            }
            NSInteger last = -1;

            NSInteger hr = hour;
            NSInteger cHour = hr;
            NSInteger count = 0;
            for (NSInteger j = 0; j < 6; j++) {
                SMRouteTimeInfo *timeInfo = [SMRouteTimeInfo new];
                timeInfo.routeInfo = singleRouteInfo;

                num = ((NSNumber *)[srcArr objectAtIndex:(j + index) % srcArr.count]).intValue;

                if (last >= 0) {
                    if (num < last) {
                        cHour++;
                    }
                }
                else if (num < mins) {
                    cHour++;
                }

                SMTime *srcTime = [SMTime new];
                srcTime.hour = cHour;
                srcTime.minutes = num;
                timeInfo.sourceTime = srcTime;

                last = num;
                SMTime *destTime = [SMTime new];
                for (SMArrivalInfo *ai in lineData.arrivalInfos) {
                    if (ai.station == singleRouteInfo.destStation) {
                        NSArray *destArr = (departure) ? ai.departures : ai.arrivals;
                        num = ((NSNumber *)[destArr objectAtIndex:(j + index) % destArr.count]).intValue;
                        NSInteger destHour = srcTime.hour;
                        if (num < srcTime.minutes) {
                            destHour++;
                        }
                        destTime.hour = destHour;
                        destTime.minutes = num;
                        timeInfo.destTime = destTime;
                        break;
                    }
                }

                if (timeInfo.destTime.minutes >= 0 && timeInfo.sourceTime.minutes >= 0) {
                    [arr addObject:timeInfo];
                    count++;
                }

                if (count == 3) break;
            }
        }
    }
}
@end
