//
//  SMStationPickerVIew.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/10/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMStationPickerView.h"

@implementation SMStationPickerView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor= [UIColor whiteColor];
        self.pickerView= [[UIPickerView alloc] initWithFrame:CGRectMake(0.1*frame.size.width, 0.1*frame.size.height, 0.8*frame.size.width, 0.8*frame.size.height)];
        [self addSubview:self.pickerView];
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
