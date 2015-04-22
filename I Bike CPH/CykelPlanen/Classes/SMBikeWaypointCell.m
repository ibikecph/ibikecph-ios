//
//  SMBikeWaypointCell.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/5/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMBikeWaypointCell.h"

@implementation SMBikeWaypointCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setupWithString:(NSString*)str{
    self.labelAddressBottom.adjustsFontSizeToFitWidth= YES;
    
    self.labelAddressTop.text= @"";
    self.labelAddressBottom.text= @"";
    NSArray* comps= [str componentsSeparatedByString:@","];
    int i=0;
    for(i=0; i<comps.count; i++){
        NSString* val= [comps objectAtIndex:i];
        if(val.length>0){
            self.labelAddressTop.text= val;
            break;
        }else{
            self.labelAddressTop.text= @"";
        }
    }
    i++;
    NSString* val= @"";
    BOOL first= YES;
    for(;i<comps.count; i++){
        if(!first)
            val= [val stringByAppendingString:@", "];
        val= [self formatAddressComponent:[val stringByAppendingString:[comps objectAtIndex:i]]];
        
        first= NO;
    }
    
    
    self.labelAddressBottom.text= val;
    
    
    self.selectionStyle= UITableViewCellSelectionStyleNone;

}

-(NSString*)formatAddressComponent:(NSString*)comp{
    NSString* trimmed= [comp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    int i = 0;
    
    while ((i < [trimmed length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[trimmed characterAtIndex:i]]) {
        i++;
    }
    return [trimmed substringFromIndex:i];
}
@end
