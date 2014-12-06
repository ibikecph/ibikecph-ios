//
//  SMRouteInfoViewController.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/2/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteInfoViewController.h"
#import "SMTransportation.h"
#import "SMRouteTimeInfo.h"
#import "SMTrain.h"
#import "SMRouteTimeInfo.h"
@interface SMRouteInfoViewController ()

@end

@implementation SMRouteInfoViewController {
    NSDateFormatter* dateFormatter;
    NSMutableArray* times;
    NSXMLParser* idParser;
    NSXMLParser* tripParser;
    
    SMRouteTimeInfo* currentTimeInfo;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {}
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = translateString(@"route_info");
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    dateFormatter= [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd. MMM YYYY"];
    
    [self filterLines];
}

-(void)filterLines {
    SMTransportation* transportation= [SMTransportation instance];
    NSDate* date= [NSDate new];
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *weekdayComponents =[cal components:NSWeekdayCalendarUnit fromDate:date];
    NSDateComponents *timeComponents =[cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
    NSInteger weekday = [weekdayComponents weekday];

    int hour= [timeComponents hour];
    int mins= [timeComponents minute];

    SMTime* cTime=[SMTime new];
    cTime.hour= hour;
    cTime.minutes= mins;
    
    if(self.singleRouteInfo.type == SMStationInfoTypeLocalTrain){
        // temp
        NSArray* trains= [SMTransportation instance].trains;
                NSMutableArray* timesArray= [NSMutableArray new];
        for(SMTrain* train in trains){
            NSArray* array= [train routeTimestampsForSourceStation:self.singleRouteInfo.sourceStation destinationStation:self.singleRouteInfo.destStation forDay:weekday time:cTime];
            if(array){
                [timesArray addObjectsFromArray:array];
            }
        }
        
        [timesArray sortUsingComparator:^NSComparisonResult(SMRouteTimeInfo* t1, SMRouteTimeInfo* t2){
            SMTime* src= [[SMTime alloc] initWithTime:t1.sourceTime];
            SMTime* src2= [[SMTime alloc] initWithTime:t2.sourceTime];
            
            int diff1= [cTime differenceInMinutesFrom:src];
            int diff2= [cTime differenceInMinutesFrom:src2];
            if(diff1 > diff2)
                return NSOrderedDescending;
            else
                return NSOrderedAscending;
            
        }];
     
        BOOL hasDuplicates= NO;
        do {
            hasDuplicates= NO;
            
            for(int i=0; i<((int)timesArray.count)-1; i++){
                
                SMRouteTimeInfo* first= timesArray[i];
                for(int j=i+1; j<timesArray.count; j++){
                    SMRouteTimeInfo* second= timesArray[j];
                    if([second.sourceTime isEqual:first.sourceTime]){
                        [timesArray removeObject:second];
                        hasDuplicates= YES;
                        break;
                    }
                    if(hasDuplicates)
                        break;
                    
                }
            }
        } while(hasDuplicates);
        times = [NSArray arrayWithArray:timesArray];

    }else{
        NSString* urlString= [NSString stringWithFormat:@"http://xmlopen.rejseplanen.dk/bin/rest.exe/location?input=%@",[self.singleRouteInfo.sourceStation.name urlEncode]];
        idParser= [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
        idParser.delegate= self;
        [idParser parse];
    }
    /*
    else if(self.singleRouteInfo.type == SMStationInfoTypeTrain){
        TravelTime time;
        // determine current time (weekday / weekend / weekend night)
        
        if([self isNightForDayAtIndex:6 dayIndex:[weekdayComponents weekday] hour:cTime.hour] || [self isNightForDayAtIndex:7 dayIndex:[weekdayComponents weekday] hour:cTime.hour]){
            time= TravelTimeWeekendNight;
        }else if(weekday>=2 && weekday<=6){
            time= TravelTimeWeekDay;
        }else if(weekday==7 || weekday==1){
            time= TravelTimeWeekend;
        }
        
        NSMutableArray* timesArr= [NSMutableArray new];
        
        for(SMTransportationLine* line in transportation.lines){
            NSLog(@"line: %@, station: %@", line.name, self.singleRouteInfo.sourceStation.name);
            if([line containsRouteFrom:self.singleRouteInfo.sourceStation to:self.singleRouteInfo.destStation forTime:time]){
                [line addTimestampsForRouteInfo:self.singleRouteInfo array:timesArr currentTime:date time:time];
            }
        }
        times= [NSArray arrayWithArray:timesArr];
    }else if(self.singleRouteInfo.type == SMStationInfoTypeMetro){
        SMTime* firstTime= [[SMTime alloc] initWithTime:cTime];
        NSMutableArray* arr= [NSMutableArray new];
        
        int diff= [self.singleRouteInfo.transportationLine differenceFrom:self.singleRouteInfo.sourceStation to:self.singleRouteInfo.destStation];
        NSArray* stations = self.singleRouteInfo.transportationLine.stations;
        int startIndex = 0;
        int endIndex = 0;
        for (int i=0; i<[stations count]; i++) {
            if ( [[stations objectAtIndex:i] isEqual:self.singleRouteInfo.sourceStation] ) {
                startIndex = i;
            }
            
            if ( [[stations objectAtIndex:i] isEqual:self.singleRouteInfo.destStation] ) {
                endIndex = i;
            }
        }
        
        // TO DO: separate M1 and M2 metro lines
        
        int minutesBetweenDeparture = 2;
        int h = firstTime.hour;
        if (startIndex < 7) {
            if ( (h >= 7 && h < 9) || (h >= 14 && h < 18) ) {
                // Rush hours
                minutesBetweenDeparture = 2;
            } else {
                // ...
                minutesBetweenDeparture = 3;
            }
            
            // Nights (work days and sunday)
            if (h >= 0 && h < 5 && weekdayComponents.weekday >=1 && weekdayComponents.weekday < 6) {
                minutesBetweenDeparture = 20;
            }
            
            // Nights (weekends)
            if (h >= 1 && h < 7 && weekdayComponents.weekday >=6 && weekdayComponents.weekday <= 7) {
                minutesBetweenDeparture = 8;
            }
            
            if(firstTime.minutes%2==1){
                [firstTime addMinutes:1];
            }
        } else {
            if ( (h >= 7 && h < 9) || (h >= 14 && h < 18) ) {
                // Rush hours
                minutesBetweenDeparture = 4;
            } else {
                // ...
                minutesBetweenDeparture = 6;
            }
            
            // Nights (work days and sunday)
            if (h >= 0 && h < 5 && weekdayComponents.weekday >=1 && weekdayComponents.weekday < 6) {
                minutesBetweenDeparture = 30;
            }
            
            // Nights (weekends)
            if (h >= 1 && h < 7 && weekdayComponents.weekday >=6 && weekdayComponents.weekday <= 7) {
                minutesBetweenDeparture = 15;
            }
            
            if(firstTime.minutes%2==1) {
                [firstTime addMinutes:1];
            }
            [firstTime addMinutes:2];
        }
        
        if (firstTime.minutes >= 60) {
            firstTime.minutes = firstTime.minutes % 60;
            firstTime.hour += 1;
            firstTime.hour = firstTime.hour % 24;
        }
        
        NSLog(@"start index: %d, end index: %d", startIndex, endIndex);
        
        double metroTimingConst[] = {0.7335,1.4172,1.0357,0.9220,2.0112,1.9194,1.4138,0.9644,1.7651,0.8496,1.1164,0.7781,0.9434,1.0419,5.1643,1.5944,1.3921,0.6224,1.2332,1.3312,1.0685}; //,0.0000};
        double m1Const[] = {0.7335,1.4172,1.0357,0.9220,2.0112,1.9194,1.4138,0.9644,1.0651,0.8496,1.1164,0.7781,0.9434,1.0419};
        double m2Const[] = {0.7335,1.4172,1.0357,0.9220,2.0112,1.9194,1.4138,0.9644,1.0651,1.3944,1.1921,0.6224,1.2332,1.3312,0.5685};
        
        double totalTime = 0;
        for (int i=0; i<[stations count]; i++) {
            totalTime += metroTimingConst[i] * 2.0;
        }
        
        NSLog(@"Total time for metro: %f", totalTime);
        
        for(int i=0; i<3; i++){
            [firstTime addMinutes:minutesBetweenDeparture];

            SMTime* sTime= [[SMTime alloc] initWithTime:firstTime];
            SMTime* destTime= [[SMTime alloc] initWithTime:sTime];
            
            //[destTime addMinutes:diff*2];
            float travelTime = 0;
            float averageTimePerStation = 25.0 / 14.0;
            float magicNumber = 19.0f/22.0f;
            
            NSLog(@"Stations for route:");
            if (startIndex < endIndex) {
                for (int st=startIndex; st<endIndex; st++) {
                    travelTime += averageTimePerStation * metroTimingConst[st] * magicNumber;
                    SMStationInfo* station = [stations objectAtIndex:st];
                    NSLog(@"%@ -> [%d]", station.name, st);
                }
            } else {
                for (int st=endIndex; st<startIndex; st++) {
                    travelTime += averageTimePerStation * metroTimingConst[st] * magicNumber;
                }
            }
            
            [destTime addMinutes:round(travelTime) ];
            
            SMRouteTimeInfo* routeTimeInfo= [[SMRouteTimeInfo alloc] initWithRouteInfo:self.singleRouteInfo sourceTime:sTime destinationTime:destTime];
            [arr addObject:routeTimeInfo];
        }
        
        times= [NSArray arrayWithArray:arr];
    } */
    [self.tableView reloadData];

}

-(BOOL)isNightForDayAtIndex:(int)index dayIndex:(int)dayIndex hour:(int)hour{
    return (dayIndex== index && hour>20) || ( ((dayIndex+1)%7) == index && hour<5);
}

-(BOOL)isDayForDayAtIndex:(int)index components:(NSDateComponents*)comps{
    return [comps weekday] == index && [comps hour]<20 && [comps hour]>5;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)didTapOnBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            return 132;
        case 1:
        case 3:
        case 5:
            return 40;
        case 2:
        case 4:
            return 5; //29;
    }
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell;
    
    switch (indexPath.row) {
        case 0:
        {
            cell= [tableView dequeueReusableCellWithIdentifier:@"CellHeader"];

            NSDate* today = [NSDate date];
            NSDateFormatter* dateFormatterTime = [[NSDateFormatter alloc] init];
            [dateFormatterTime setTimeStyle:NSDateFormatterShortStyle];
            NSString* currentTime = [dateFormatterTime stringFromDate:today];
            
            UILabel* lbl= (UILabel*)[cell viewWithTag:1];
            [lbl setText:self.singleRouteInfo.sourceStation.name];
            lbl= (UILabel*)[cell viewWithTag:2];
            [lbl setText:self.singleRouteInfo.destStation.name];
            lbl= (UILabel*)[cell viewWithTag:3];
            [lbl setText:[NSString stringWithFormat:@"%@, %@ %@", [dateFormatter stringFromDate:[NSDate new]], translateString(@"departures_at"), currentTime ]];
            
            lbl= (UILabel*)[cell viewWithTag:11];
            [lbl setText:translateString(@"departure")];
            lbl= (UILabel*)[cell viewWithTag:12];
            [lbl setText:translateString(@"arrival")];
            lbl= (UILabel*)[cell viewWithTag:13];
            [lbl setText:translateString(@"Time")];
            lbl= (UILabel*)[cell viewWithTag:14];
            [lbl setText:translateString(@"shift")];
            
            lbl= (UILabel*)[cell viewWithTag:21];
            [lbl setText:translateString(@"From:")];
            lbl= (UILabel*)[cell viewWithTag:22];
            [lbl setText:translateString(@"To:")];
            lbl= (UILabel*)[cell viewWithTag:23];
            [lbl setText:[translateString(@"Time") stringByAppendingString:@":"]];
            break;
        }
        case 1:
        case 3:
        case 5:
        {
            cell= [tableView dequeueReusableCellWithIdentifier:@"CellData"];
            SMRouteTimeInfo* routeTimeInfo;
            if(times.count >=3){
                routeTimeInfo= [times objectAtIndex:indexPath.row/2];
            }
            
            SMTime* difference= [routeTimeInfo.sourceTime differenceFrom:routeTimeInfo.destTime];
            UILabel* lbl= (UILabel*)[cell viewWithTag:1];
            [lbl setText:[NSString stringWithFormat:@"%02d:%02d",routeTimeInfo.sourceTime.hour, routeTimeInfo.sourceTime.minutes]];
            lbl= (UILabel*)[cell viewWithTag:2];
            [lbl setText:[NSString stringWithFormat:@"%02d:%02d",routeTimeInfo.destTime.hour, routeTimeInfo.destTime.minutes]];
            lbl= (UILabel*)[cell viewWithTag:3];
            [lbl setText:[NSString stringWithFormat:@"%02d:%02d",difference.hour, difference.minutes]];
            lbl= (UILabel*)[cell viewWithTag:4];
            [lbl setText:@"0"];
            UIColor* bgColor;
            if(indexPath.row==1){
                bgColor= [UIColor colorWithRed:250.0/255.0 green:255.0/255.0 blue:190.0/255.0 alpha:1.0];
            }else{
                bgColor= [UIColor whiteColor];
            }
            [cell.contentView setBackgroundColor:bgColor];
            break;
        }
        case 2:
        case 4:
        {
            cell= [tableView dequeueReusableCellWithIdentifier:@"CellText"];
            UILabel* lbl= (UILabel*)[cell viewWithTag:1];
            [lbl setText:@"Long text Long text Long text Long text Long text "];
            break;
        }
        default:
            cell= nil;
    }
    cell.selectionStyle= UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

#pragma mark - parser delegate

-(NSString*)eightCharacterFormattedDouble:(double)val{
    NSString* str= [NSString stringWithFormat:@"%lf",val];
    str= [str stringByReplacingOccurrencesOfString:@"." withString:@""];
    if(str.length>8){
        str= [str substringToIndex:8];
    }
    
    while (str.length<8) {
        str= [str stringByAppendingString:@"0"];
    }
    
    return str;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    if(parser== idParser && [elementName isEqualToString:@"StopLocation"]){
        NSString* stationID= [attributeDict objectForKey:@"id"];
        [parser abortParsing];
        
        double lat= self.singleRouteInfo.destStation.latitude;
        double lon= self.singleRouteInfo.destStation.longitude;
        
        NSString* destX= [self eightCharacterFormattedDouble:lon];
        NSString* destY= [self eightCharacterFormattedDouble:lat];
        NSString* destCoordName= [self.singleRouteInfo.destStation.name urlEncode];

        NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate* date= [NSDate new];
        
        // Rejseplanen returns trains that are already departed
        // So adding 5 minutes to current time might help here
        NSDate *datePlusFiveMinutes = [date dateByAddingTimeInterval:60*5];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:datePlusFiveMinutes];
        NSDateComponents *timeComponents =[cal components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:datePlusFiveMinutes];
        
        int hour= [timeComponents hour];
        int mins= [timeComponents minute];
        
        NSLog(@"Modified TIME: %d:%d", hour, mins);

        NSString* dateString= [NSString stringWithFormat:@"%02d.%02d",[components day], [components month]];
        NSString* timeString= [NSString stringWithFormat:@"%d:%d",hour, mins];
        NSString* URLString= [NSString stringWithFormat:@"http://xmlopen.rejseplanen.dk/bin/rest.exe/trip?originId=%@&destCoordX=%@&destCoordY=%@&destCoordName=%@&date=%@&time=%@&useBus=0",
                              stationID, destX, destY, destCoordName, dateString, timeString];
        [self performSelectorOnMainThread:@selector(parseTripsWithURLString:) withObject:URLString waitUntilDone:NO];
//        NSLog(@"Parsed %@",(parsed)?@"YES":@"NO");
    }else if( parser == tripParser){
        if([elementName isEqualToString:@"Leg"]){
            NSString* type= [attributeDict objectForKey:@"type"];
            if([type isEqualToString:@"S"] || [type isEqualToString:@"M"]){
                currentTimeInfo= [SMRouteTimeInfo new];
                currentTimeInfo.routeInfo= self.singleRouteInfo;
            }else{
                currentTimeInfo= nil;
            }
        }else if([elementName isEqualToString:@"Origin"]){
            if(currentTimeInfo)
                currentTimeInfo.sourceTime= [SMTime timeFromString:[attributeDict objectForKey:@"time"]];
        }else if([elementName isEqualToString:@"Destination"]){
            if(currentTimeInfo){
                currentTimeInfo.destTime= [SMTime timeFromString:[attributeDict objectForKey:@"time"]];
                if(!times){
                    times= [NSMutableArray new];
                }
                [times addObject:currentTimeInfo];
                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            }
        }
    }
}

-(void)parseTripsWithURLString:(NSString*)URLString{
    NSError* error;

    NSString* string= [NSString stringWithContentsOfURL:[NSURL URLWithString:URLString] encoding:NSUTF8StringEncoding error:&error];

    if(error){
        NSLog(@"%@",error.localizedDescription);
    }else{
        NSLog(@"%@",string);
    }
    tripParser= [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:URLString]];
    tripParser.delegate= self;
    BOOL parsed= [tripParser parse];
    if(!parsed){
        NSLog(@"%@",tripParser.parserError.localizedDescription);
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{

}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
