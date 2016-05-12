//
//  SMTransportation.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMArrivalInfo.h"
#import "SMDepartureInfo.h"
#import "SMNode.h"
#import "SMRelation.h"
#import "SMTime.h"
#import "SMTrain.h"
#import "SMTransportation.h"
#import "SMTransportationLine.h"
#import "SMWay.h"

#define CACHE_FILE_NAME @"StationsCached.data"
#define MAX_CONCURENT_ROUTE_THREADS 4

#define KEY_LINES @"KeyLines"

static NSOperationQueue *stationQueue;

@implementation SMTransportation {
    NSMutableArray *relations;
    SMRelation *relation;

    NSXMLParser *basicParser;
    NSXMLParser *detailsParser;

    NSMutableArray *allNodes;

    dispatch_queue_t queue;
}

+ (SMTransportation *)sharedInstance
{
    static SMTransportation *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      stationQueue = [[NSOperationQueue alloc] init];

      //        NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      //        NSString *documentDirectory = [documentDirectories objectAtIndex:0];
      //        NSString *myFilePath = [documentDirectory stringByAppendingPathComponent:CACHE_FILE_NAME];

      //        sharedInstance= [NSKeyedUnarchiver unarchiveObjectWithFile:myFilePath];

      if (!sharedInstance) {
          sharedInstance = [SMTransportation new];
      }

    });

    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        allNodes = [NSMutableArray new];
        self.lines = [NSMutableArray new];
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0L);

        dispatch_async(queue, ^{
          self.dataLoaded = NO;
          [self loadStations];
          [self loadLocalTrains];
          [self loadDepartureTimes];

          self.dataLoaded = YES;
          [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DID_PARSE_DATA_KEY object:nil];

        });
    }
    return self;
}

- (void)save
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    NSString *myFilePath = [documentDirectory stringByAppendingPathComponent:CACHE_FILE_NAME];

    [NSKeyedArchiver archiveRootObject:self toFile:myFilePath];
}

- (void)validateAndSave
{
    for (SMTransportationLine *line in self.lines) {
        for (SMStationInfo *sInfo in line.stations) {
            if (![sInfo isValid]) return;
        }
    }

    [self save];
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.lines forKey:KEY_LINES];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.lines = [aDecoder decodeObjectForKey:KEY_LINES];
    }
    return self;
}

+ (NSOperationQueue *)transportationQueue
{
    static NSOperationQueue *sRequestQueue;

    if (!sRequestQueue) {
        sRequestQueue = [NSOperationQueue new];
        sRequestQueue.maxConcurrentOperationCount = MAX_CONCURENT_ROUTE_THREADS;
    }

    return sRequestQueue;
}

//-(void) loadDummyData{
//    NSString * filePath0 = [[NSBundle mainBundle] pathForResource:@"Albertslundruten" ofType:@"line"];
//    NSString * filePath1 = [[NSBundle mainBundle] pathForResource:@"Farumruten" ofType:@"line"];
//    SMTransportationLine * line0 = [[SMTransportationLine alloc] initWithFile:filePath0];
//    SMTransportationLine * line1 = [[SMTransportationLine alloc] initWithFile:filePath1];
//
//    self.lines = @[line0,line1];
//}

- (void)didFinishFetchingStationData
{
    [self initializeLines];
}

- (void)initializeLines
{
    NSMutableArray *tempLines = [NSMutableArray new];

    for (SMRelation *rel in relations) {
        [tempLines addObject:[[SMTransportationLine alloc] initWithRelation:rel]];
    }

    self.lines = [NSArray arrayWithArray:tempLines];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STATIONS_FETCHED object:nil];
}

// http://overpass-api.de/api/interpreter?data=rel(50.745,7.17,50.75,7.18)[route=bus];out;
//-(void)pullData{
//    NSMutableURLRequest* req= [[NSMutableURLRequest alloc] initWithURL:[NSURL
//    URLWithString:@"http://overpass-api.de/api/interpreter?data=rel(55,12,56,13)[route=bus];out;"]];
//
//    [NSURLConnection sendAsynchronousRequest:req queue:stationQueue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error){
//        NSString* s= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
////        NSLog(@"%@",s);
//        basicParser= [[NSXMLParser alloc] initWithData:data];
//        basicParser.delegate= self;
//        relations= [NSMutableArray new];
//        [basicParser parse];
//
//    }];
//}

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict
{
    if (parser == basicParser) {
        if ([elementName isEqualToString:@"relation"]) {
            if (relation) {
                [relations addObject:relation];
            }
            relation = [SMRelation new];
            return;
        }

        NSString *type = [attributeDict objectForKey:@"type"];
        NSString *role = [attributeDict objectForKey:@"role"];
        NSString *ref = [attributeDict objectForKey:@"ref"];
        if ([type isEqualToString:@"way"]) {
            SMWay *way = [SMWay new];
            way.ref = ref;
            way.role = role;
            [relation.ways addObject:way];
        }
        else if ([type isEqualToString:@"node"]) {
            NSArray *filteredNodes = [allNodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.ref=%@", ref]];
            SMNode *node;
            if (filteredNodes.count > 0) {
                node = [filteredNodes objectAtIndex:0];
            }
            else {
                node = [SMNode new];
                node.ref = ref;
                node.role = role;
                [allNodes addObject:node];
            }

            [relation.nodes addObject:node];
        }
    }
    else if (parser == detailsParser) {
        if ([elementName isEqualToString:@"node"]) {
            NSString *nodeID = [attributeDict objectForKey:@"id"];
            ;

            NSNumber *lat = [attributeDict objectForKey:@"lat"];
            NSNumber *lng = [attributeDict objectForKey:@"lon"];

            NSArray *filteredNodes = [allNodes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.ref=%@", nodeID]];
            SMNode *node = nil;

            if (filteredNodes.count > 0) {
                node = [filteredNodes objectAtIndex:0];
                NSLog(@"Setting %lf %lf for %@", lat.doubleValue, lng.doubleValue, nodeID);
                node.coordinate = CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue);
            }
        }
    }
}

//- (void)parserDidEndDocument:(NSXMLParser *)parser{
//    if(parser==basicParser){
//        [self fetchDetails];
//    }else if(parser==detailsParser){
//        [self didFinishFetchingStationData];
//    }
//}

//-(void)fetchDetails{
//    NSMutableURLRequest* req= [[NSMutableURLRequest alloc] initWithURL:[NSURL
//    URLWithString:[@"http://overpass-api.de/api/interpreter?data=rel(55,12,56,13)[route=bus];>;out;"
//    stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
//
//    [NSURLConnection sendAsynchronousRequest:req queue:stationQueue completionHandler:^(NSURLResponse* resp, NSData* data, NSError* error){
//        NSString* s= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
////        NSLog(@"%@",s);
//        detailsParser= [[NSXMLParser alloc] initWithData:data];
//        detailsParser.delegate= self;
//
//        [detailsParser parse];
//
//    }];
//}

- (void)loadLocalTrains
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"local-trains-timetable" ofType:@"json"];
    NSError *error;
    NSDictionary *dict =
        [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error];
    NSArray *trainsArr = [dict objectForKey:@"local-trains"];
    NSMutableArray *trains = [NSMutableArray new];
    for (NSDictionary *arr in trainsArr) {
        NSArray *stations = [arr objectForKey:@"stations"];

        NSDictionary *departureDict = [arr objectForKey:@"departure"];

        NSArray *weekDaysData = [departureDict objectForKey:@"weekdays"];
        NSArray *days = [NSArray arrayWithObjects:@0, @1, @2, @3, @4, nil];
        SMTime *time = [SMTime new];

        [self parseStationsFromArray:weekDaysData dataTable:nil stations:stations trains:trains days:days];

        // week days
        for (NSDictionary *infoDict in weekDaysData) {
            NSString *startTimeNum = [infoDict objectForKey:@"start-time"];
            NSString *endTimeNum = [infoDict objectForKey:@"end-time"];
            NSArray *dataArr = [infoDict objectForKey:@"data"];
            NSUInteger trainCount = dataArr.count / stations.count;

            SMTime *startTime = [self timeFromString:startTimeNum separator:@"."];
            SMTime *endTime = [self timeFromString:endTimeNum separator:@"."];

            if (startTime.hour > endTime.hour) {
                endTime.hour += 24;
            }
            for (NSInteger j = 0; j < trainCount; j++) {
                SMTrain *train = [SMTrain new];
                [trains addObject:train];
                for (NSInteger i = 0; i < dataArr.count; i += trainCount) {
                    NSInteger index = (i / trainCount);
                    if (index >= stations.count) {
                        continue;
                    }
                    SMStationInfo *station = [self stationNamed:stations[index]];

                    NSNumber *minute = dataArr[i + j];
                    for (NSInteger hour = startTime.hour; hour <= endTime.hour; hour++) {
                        time.hour = hour;
                        time.minutes = minute.intValue;
                        if ([time isBetween:startTime and:endTime]) {
                            SMArrivalInformation *info = [train informationForStation:station];
                            [info addDepartureTime:[time copy] forDays:days];
                        }
                    }
                }
            }
        }

        // weekend
        NSDictionary *weekend = [departureDict objectForKey:@"weekend"];
        NSArray *dataTableArr = [weekend objectForKey:@"data-table"];
        NSArray *arr = [weekend objectForKey:@"saturday"];

        days = [NSArray arrayWithObject:@5];
        [self parseStationsFromArray:arr dataTable:dataTableArr stations:stations trains:trains days:days];

        arr = [weekend objectForKey:@"sunday"];
        days = [NSArray arrayWithObject:@6];
        [self parseStationsFromArray:arr dataTable:dataTableArr stations:stations trains:trains days:days];
    }

    self.trains = [NSArray arrayWithArray:trains];
}

- (void)parseStationsFromArray:(NSArray *)d
                     dataTable:(NSArray *)dataTableArr
                      stations:(NSArray *)stations
                        trains:(NSMutableArray *)trains
                          days:(NSArray *)days
{
    NSInteger index = 0;
    SMTime *time = [SMTime new];
    for (NSDictionary *dict in d) {
        NSString *startTimeNum = [dict objectForKey:@"start-time"];
        NSString *endTimeNum = [dict objectForKey:@"end-time"];
        NSArray *dataArr = [dict objectForKey:@"data"];
        if (!dataArr) {
            dataArr = dataTableArr[index];
        }

        NSUInteger trainCount = dataArr.count / stations.count;
        SMTime *startTime = [self timeFromString:startTimeNum separator:@"."];
        SMTime *endTime = [self timeFromString:endTimeNum separator:@"."];

        if (startTime.hour > endTime.hour) {
            endTime.hour += 24;
        }
        for (NSUInteger j = 0; j < trainCount; j++) {
            SMTrain *train = [SMTrain new];
            [trains addObject:train];
            for (NSInteger i = 0; i < dataArr.count; i += trainCount) {
                NSInteger index = (i / trainCount);
                if (index >= stations.count) {
                    continue;
                }
                SMStationInfo *station = [self stationNamed:stations[index]];
                NSNumber *minute = dataArr[i + j];
                for (NSInteger hour = startTime.hour; hour <= endTime.hour; hour++) {
                    time.hour = hour;
                    time.minutes = minute.intValue;
                    if ([time isBetween:startTime and:endTime]) {
                        SMArrivalInformation *info = [train informationForStation:station];
                        [info addDepartureTime:[time copy] forDays:days];
                    }
                }
            }
        }

        index++;
    }
}

//    {
//        "line" : "910",
//        "first-station" : "Nærum",
//        "last-station" : "Jægersborg",
//
//        "stations":["København H","Vesterport","Nørreport","Østerport","Jægersborg","Jægersborg","Nørgaardsvej","Lyngby
//        Lokal","Fuglevad","Brede","Ørholm","Ravnholm"],
//
//        "departure": {
//            "weekdays" : [
//                          {"start-time":5.14, "end-time":0.34, "data":[14, 34, 54, 16, 36, 56, 17, 37, 57, 19, 39, 59, 22, 42, 2, 24, 44, 4, 25, 45,
//                          5, 27, 47, 7, 29, 49, 9, 43, 3, 23, 45, 5, 25, 47, 7, 27, 50, 10, 30]},
//                          {"start-time":1.14, "end-time":1.14, "data":[14, 16, 17, 19, 22, 24, 25, 27, 29, 43, 45, 47, 50]},
//                          {"start-time":6.44, "end-time":9.04, "data":[4, 24, 44, 6, 26, 46, 7, 27, 47, 9, 29, 49, 12, 32, 52, 14, 34, 54, -1, -1,
//                          -1, 17, 37, 57, 19, 39, 59, 33, 53, 13, 35, 55, 15, 37, 57, 17, 40, 0, 20]},
//                          {"start-time":15.44, "end-time":17.04, "data":[4, 24, 44, 6, 26, 46, 7, 27, 47, 9, 29, 49, 12, 32, 52, 14, 34, 54, -1, -1,
//                          -1, 17, 37, 57, 19, 39, 59, 33, 53, 13, 35, 55, 15, 37, 57, 17, 40, 0, 20]}
//                          ],
//
//            "weekend" : {
//                "saturday" : [
//                              {"start-time":5.14, "end-time":5.14},
//                              {"start-time":5.54, "end-time":5.54},
//                              {"start-time":6.34, "end-time":21.54},
//                              {"start-time":22.34, "end-time":22.34},
//                              {"start-time":23.14, "end-time":23.14},
//                              {"start-time":23.54, "end-time":23.54},
//                              {"start-time":0.34, "end-time":0.34},
//                              {"start-time":1.14, "end-time":1.14}
//                              ],
//
//                "sunday" : [
//                            {"start-time":6.14, "end-time":6.14},
//                            {"start-time":6.54, "end-time":6.54},
//                            {"start-time":7.34, "end-time":21.54},
//                            {"start-time":22.34, "end-time":22.34},
//                            {"start-time":23.14, "end-time":23.14},
//                            {"start-time":23.54, "end-time":23.54},
//                            {"start-time":0.34, "end-time":0.34},
//                            {"start-time":1.14, "end-time":1.14}
//                            ],
//
//                "data-table": [
//                               [14,16,17,19,22,24,25,27,29,43,45,47,50],
//                               [54,56,57,59,2,4,5,7,9,23,25,27,30],
//
//                               [14, 34, 54, 16, 36, 56, 17, 37, 57, 19, 39, 59, 22, 42, 2, 24, 44, 4, 25, 45, 5, 27, 47, 7, 29, 49, 9, 43, 3, 23,
//                               45, 5, 25, 47, 7, 27],
//
//                               [34,36,37,39,42,44,45,47,49,3,5,7,10],
//                               [14,16,17,19,22,24,25,27,29,43,45,47,50],
//                               [54,56,57,59,2,4,5,7,9,23,25,27,30],
//                               [34,36,37,39,42,44,45,47,49,3,5,7,10],
//                               [14,16,17,19,22,24,25,27,29,43,45,47,50]
//                               ]
//
//            }
//        },

- (void)loadStations
{
    NSString *KEY_STATIONS_TYPE = @"type";
//    NSString *KEY_STATIONS_LINES = @"line";
    NSString *KEY_STATIONS_COORDS = @"coords";
    NSString *KEY_STATIONS_NAME = @"name";

    NSString *TYPE_METRO = @"metro";
    NSString *TYPE_TRAIN = @"s-train";
    NSString *TYPE_SERVICE = @"service";

    NSString *TYPE_LOCAL = @"local-train";

    // parse stations

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
    NSError *error;
    NSDictionary *dict =
        [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error];
    NSArray *stationsArr = [dict objectForKey:@"stations"];
    NSMutableArray *tempStations = [NSMutableArray new];

    for (NSDictionary *stationDict in stationsArr) {
        NSString *type = [stationDict objectForKey:KEY_STATIONS_TYPE];
//        NSString *line = [stationDict objectForKey:KEY_STATIONS_LINES];
        NSString *coords = [stationDict objectForKey:KEY_STATIONS_COORDS];
        NSString *name = [stationDict objectForKey:KEY_STATIONS_NAME];
        // parse coordinates
        NSRange range = [coords rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" ,"]];
        CLLocationDegrees lon = [coords substringToIndex:range.location].doubleValue;
        CLLocationDegrees lat = [coords substringFromIndex:range.location].doubleValue;

        // determine station type
        SMStationInfoType stationType = SMStationInfoTypeUndefined;
        if ([type.lowercaseString isEqualToString:TYPE_METRO]) {
            stationType = SMStationInfoTypeMetro;
        }
        else if ([type.lowercaseString isEqualToString:TYPE_TRAIN]) {
            stationType = SMStationInfoTypeTrain;
        }
        else if ([type.lowercaseString isEqualToString:TYPE_SERVICE]) {
            stationType = SMStationInfoTypeService;
        }
        else if ([type.lowercaseString isEqualToString:TYPE_LOCAL]) {
            stationType = SMStationInfoTypeLocalTrain;
        }
        SMStationInfo *stationInfo = [[SMStationInfo alloc] initWithLongitude:lon latitude:lat name:name type:stationType];
        [tempStations addObject:stationInfo];
    }

    // parse lines
    filePath = [[NSBundle mainBundle] pathForResource:@"transportation-lines" ofType:@"json"];

    dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error];
    NSMutableArray *tempLines = [NSMutableArray new];
    NSArray *lines = [dict objectForKey:@"lines"];
    for (NSDictionary *lineDict in lines) {
        NSString *lineName = [lineDict objectForKey:@"name"];
        NSArray *stations = [lineDict objectForKey:@"stations"];
        NSString *type = [lineDict objectForKey:@"type"];
        NSMutableArray *lineStations = [NSMutableArray new];
        SMTransportationLine *line = [[SMTransportationLine alloc] init];

        line.name = lineName;
        //        NSLog(@"Line %@, stations: ", lineName);
        for (NSNumber *stationIndex in stations) {
            [lineStations addObject:[tempStations objectAtIndex:stationIndex.intValue]];
            //            NSLog(@"%@ %d", ((SMStationInfo*)[tempStations objectAtIndex:stationIndex.intValue]).name, stationIndex.intValue);
        }

        SMStationInfoType stationType = SMStationInfoTypeUndefined;
        if ([type.lowercaseString isEqualToString:TYPE_METRO]) {
            stationType = SMStationInfoTypeMetro;
        }
        else if ([type.lowercaseString isEqualToString:TYPE_TRAIN]) {
            stationType = SMStationInfoTypeTrain;
        }
        else if ([type.lowercaseString isEqualToString:TYPE_SERVICE]) {
            stationType = SMStationInfoTypeService;
        }
        else if ([type.lowercaseString isEqualToString:TYPE_LOCAL]) {
            stationType = SMStationInfoTypeLocalTrain;
        }

        line.type = stationType;

        //        NSLog(@"=====\n\n");
        [line setStations:[NSArray arrayWithArray:lineStations]];
        [tempLines addObject:line];
    }

    self.allStations = [NSArray arrayWithArray:tempStations];
    self.lines = [NSArray arrayWithArray:tempLines];
}

- (void)loadDepartureTimes
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timetable-new" ofType:@"json"];
    NSError *error;
    NSDictionary *json =
        [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingAllowFragments error:&error];
    NSArray *lines = [json objectForKey:@"timetable"];

    for (NSDictionary *dict in lines) {
        NSString *lineName = [dict objectForKey:@"line"];
        SMTransportationLine *transportationLine = [self lineNamed:lineName];
        if (!transportationLine) {
            NSLog(@"Line %@ not found", lineName);
            return;
        }

        NSDictionary *weekdaysDict = [dict objectForKey:@"weekdays"];
        NSDictionary *weekendsDict = [dict objectForKey:@"weekend"];
        NSDictionary *weekendNightDict = [dict objectForKey:@"night-after-friday-saturday"];

        NSMutableArray *allLines = [NSMutableArray new];
        NSMutableArray *lineClones;

        if (weekdaysDict) {
            lineClones = [self loadLinesFromDict:weekdaysDict allLines:allLines originalLine:transportationLine time:TravelTimeWeekDay];
            [self loadDataFor:TravelTimeWeekDay lines:lineClones dict:weekdaysDict allLines:allLines];
        }

        if (weekendsDict) {
            lineClones = [self loadLinesFromDict:weekendsDict allLines:allLines originalLine:transportationLine time:TravelTimeWeekend];
            [self loadDataFor:TravelTimeWeekend lines:lineClones dict:weekendsDict allLines:allLines];
        }

        if (weekendNightDict) {
            lineClones = [self loadLinesFromDict:weekendNightDict allLines:allLines originalLine:transportationLine time:TravelTimeWeekendNight];
            [self loadDataFor:TravelTimeWeekendNight lines:lineClones dict:weekendNightDict allLines:allLines];
        }
    }
}

- (NSMutableArray *)loadLinesFromDict:(NSDictionary *)dict
                             allLines:(NSMutableArray *)allLines
                         originalLine:(SMTransportationLine *)originalline
                                 time:(TravelTime)time
{
    NSArray *arrivalArr = [dict objectForKey:@"arrival"];
    NSMutableArray *lineClones = [NSMutableArray new];

    //    NSAssert(dict!=nil, @"Arrival array doesn't exist");

    for (NSDictionary *dict in arrivalArr) {
        // set start and end station
        SMStationInfo *startStation = [self stationNamed:[dict objectForKey:@"start"]];
        SMStationInfo *endStation = [self stationNamed:[dict objectForKey:@"stop"]];
        SMTransportationLine *line;
        for (SMTransportationLine *tl in allLines) {
            if (tl.startStation == startStation && tl.endStation == endStation) {
                line = tl;
                break;
            }
        }

        if (!line) {
            if ([allLines filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", originalline.name]].count == 0) {
                // line with original name doesn't exist
                // just add it without cloning
                line = originalline;
            }
            else {
                // line with that name exists
                // clone it
                line = [originalline clone];
            }

            line.startStation = startStation;
            line.endStation = endStation;
            [allLines addObject:line];
        }

        [lineClones addObject:line];

        // day/night start/end times
        NSString *dayTime = [dict objectForKey:@"day"];
        NSString *nightTime = [dict objectForKey:@"night"];

        SMTime *dayStartTime = nil;
        SMTime *dayEndTime = nil;

        if (dayTime.length > 0) {
            NSArray *dayComps = [dayTime componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ."]];
            dayStartTime = [SMTime new];
            dayEndTime = [SMTime new];

            dayStartTime.hour = ((NSNumber *)dayComps[0]).intValue;
            dayStartTime.minutes = ((NSNumber *)dayComps[1]).intValue;

            dayEndTime.hour = ((NSNumber *)dayComps[2]).intValue;
            dayEndTime.minutes = ((NSNumber *)dayComps[3]).intValue;
        }

        SMTime *nightStartTime = nil;
        SMTime *nightEndTime = nil;

        NSArray *nightComps;
        if (nightTime.length > 0) {
            nightStartTime = [SMTime new];
            nightEndTime = [SMTime new];
            nightComps = [nightTime componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ."]];

            nightStartTime.hour = ((NSNumber *)nightComps[0]).intValue;
            nightStartTime.minutes = ((NSNumber *)nightComps[1]).intValue;

            nightEndTime.hour = ((NSNumber *)nightComps[2]).intValue;
            nightEndTime.minutes = ((NSNumber *)nightComps[3]).intValue;
        }

        SMDepartureInfo *departureInfo = [SMDepartureInfo new];
        departureInfo.dayStart = dayStartTime;
        departureInfo.dayEnd = dayEndTime;
        departureInfo.nightStart = nightStartTime;
        departureInfo.nightEnd = nightEndTime;

        switch (time) {
            case TravelTimeWeekDay:
                line.weekLineData.departureInfo = departureInfo;
                break;
            case TravelTimeWeekend:
                line.weekendLineData.departureInfo = departureInfo;
                break;
            case TravelTimeWeekendNight:
                line.weekendNightLineData.departureInfo = departureInfo;
                break;
        }
    }

    return lineClones;
}

- (void)loadDataFor:(TravelTime)time lines:(NSArray *)lineClones dict:(NSDictionary *)d allLines:(NSMutableArray *)allLines
{
    NSArray *data = [d objectForKey:@"data"];
    NSAssert(data, @"Data can't be nil.");
    for (NSDictionary *stationDict in data) {
        NSString *departureStr = [stationDict objectForKey:@"departure"];
        NSString *arrivalStr = [stationDict objectForKey:@"arrival"];
        NSArray *departures = [self timeArrayFromString:departureStr];
        NSArray *arrivals = [self timeArrayFromString:arrivalStr];

        NSString *stationName = [stationDict objectForKey:@"station"];
        SMStationInfo *station = [self stationNamed:stationName];

        if (station) {
            SMArrivalInfo *weekTravelInfo = [[SMArrivalInfo alloc] initWithDepartures:departures arrivals:arrivals];
            weekTravelInfo.station = station;
            for (SMTransportationLine *line in lineClones) {
                switch (time) {
                    case TravelTimeWeekDay:
                        [line.weekLineData.arrivalInfos addObject:weekTravelInfo];
                        break;
                    case TravelTimeWeekend:
                        [line.weekendLineData.arrivalInfos addObject:weekTravelInfo];
                        break;
                    case TravelTimeWeekendNight:
                        [line.weekendNightLineData.arrivalInfos addObject:weekTravelInfo];
                        break;
                    default:
                        break;
                }
            }
        }
        else {
            NSLog(@"Station %@ not found.", stationName);
        }
    }
}

- (NSArray *)timeArrayFromString:(NSString *)str
{
    NSMutableArray *values = [NSMutableArray new];
    NSArray *components = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    for (NSString *component in components) {
        id time;
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *myNumber = [f numberFromString:component];

        if (myNumber) {
            time = myNumber;

            [values addObject:time];
        }
    }

    return values;
}

- (SMTime *)timeFromNumber:(NSNumber *)num
{
    SMTime *time = [self timeFromString:num.stringValue separator:@"."];
    float val = num.floatValue;
    val /= 0.1f;
    float rounded = 0.0f;
    modff(val, &rounded);

    if (rounded) {
        time.minutes = time.minutes * 10;
    }

    return time;
}
- (SMTime *)timeFromString:(NSString *)str separator:(NSString *)separator
{
    NSArray *components = [str componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:separator]];
    if (components.count != 2) return nil;
    SMTime *time = [[SMTime alloc] init];
    time.hour = ((NSNumber *)components[0]).intValue;
    time.minutes = ((NSNumber *)components[1]).intValue;
    return time;
}

- (SMTransportationLine *)lineNamed:(NSString *)lineName
{
    for (SMTransportationLine *line in self.lines) {
        if ([line.name isEqualToString:lineName]) {
            return line;
        }
    }
    return nil;
}

- (SMStationInfo *)stationNamed:(NSString *)name
{
    for (SMStationInfo *station in self.allStations) {
        if ([station.name.lowercaseString isEqualToString:name.lowercaseString]) {
            return station;
        }
    }
    NSLog(@"Station not found %@", name);
    return nil;
}

- (SMStationInfo *)stationWithName:(NSString *)name
{
    NSArray *arr = [self.allStations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.name == %@", name]];

    if (arr.count > 0) {
        return arr[0];
    }

    return nil;  // station with that name doesn't exist
}
@end
