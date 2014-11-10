//
//  SMTime.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/6/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMTime.h"

@implementation SMTime

+(SMTime*)timeFromString:(NSString*)timeString{
    NSArray* timeArr= [timeString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    SMTime* time= [[SMTime alloc] init];
    time.hour= ((NSString*)timeArr[0]).intValue;
    time.minutes= ((NSString*)timeArr[1]).intValue;
    
    return time;
}

-(id)initWithTime:(SMTime*)pTime{
    if(self=[super init]){
        self.hour= pTime.hour;
        self.minutes= pTime.minutes;
    }
    return self;
}

-(int)differenceInMinutesFrom:(SMTime *)other{
    SMTime* diff= [self differenceFrom:other];
    return diff.hour*60+diff.minutes;
}

-(SMTime*)differenceFrom:(SMTime*)other{
    SMTime* time= [SMTime new];
    
    int totalMins= self.hour*60 + self.minutes;
    int otherMins= ((other.hour>=self.hour)?other.hour:(24+other.hour))*60 + other.minutes;

    otherMins-= totalMins;
    
    int hour= otherMins/60;
    int min= otherMins- hour*60;
    
    time.hour= hour;
    time.minutes= min;
    return time;
}

-(BOOL)isBetween:(SMTime*)first and:(SMTime*)second{
    int secondHour= second.hour;
    if(first.hour > second.hour ){
        secondHour+= 24;
    }

    return (self.hour>first.hour && self.hour<secondHour) || (self.hour==first.hour && self.minutes > first.minutes) || (self.hour==secondHour && self.minutes<second.minutes);
}

-(void)addMinutes:(int)mins{
    self.minutes+= mins;
    
    if(self.minutes >= 60){
        self.hour+= (self.minutes/60);
        self.minutes= (self.minutes%60);
        
        if(self.hour>=24){
            self.hour= (self.hour%24);
        }
    }
}

-(id)copy{
    SMTime* time= [SMTime new];
    time.hour= self.hour;
    time.minutes= self.minutes;
    
    return time;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%d:%d",self.hour, self.minutes];
}

-(BOOL)isEqual:(id)object{
    SMTime* other= object;
    
    return self.hour==other.hour && self.minutes==other.minutes;
}
@end
