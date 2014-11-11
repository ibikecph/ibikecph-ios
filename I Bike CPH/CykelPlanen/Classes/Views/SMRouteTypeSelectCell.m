//
//  SMRouteTypeSelectCell.m
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 06/06/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMRouteTypeSelectCell.h"

@implementation SMRouteTypeSelectCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        [cellText setTextColor:[UIColor whiteColor]];
        [cellImage setHighlighted:YES];
        [self setBackgroundColor:[UIColor colorWithRed:242.0f/255.0f green:130.0f/255.0f blue:49.0f/255.0f alpha:1.0f]];
        [self.cellCheckbox setImage:[UIImage imageNamed:@"checkbox_selected"]];
        
    } else {
        [cellText setTextColor:[UIColor colorWithRed:82.0f/255.0f green:82.0f/255.0f blue:82.0f/255.0f alpha:1.0f]];
        [cellImage setHighlighted:NO];
        [self setBackgroundColor:[UIColor whiteColor]];
         [self.cellCheckbox setImage:[UIImage imageNamed:@"checkbox"]];
    }
}

- (void)setSelected:(BOOL)selected {
    [self setSelected:selected animated:YES];
}

- (void)setupCellWithData:(NSDictionary*)data {
    cellText.text= [data objectForKey:@"name"];
    cellImage.image= [UIImage imageNamed:[data objectForKey:@"image"]];
    [cellImage setHighlightedImage:[UIImage imageNamed:[data objectForKey:@"imageHighlighted"]]];
}

+ (CGFloat)getHeight {
    return 59.0f;
}

@end
