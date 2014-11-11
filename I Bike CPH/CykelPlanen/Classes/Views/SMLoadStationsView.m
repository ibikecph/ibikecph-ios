//
//  SMLoadStationsView.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 8/22/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMLoadStationsView.h"
#import <QuartzCore/QuartzCore.h>
@implementation SMLoadStationsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        SMLoadStationsView* xibView = [[[NSBundle mainBundle] loadNibNamed:@"SMLoadStationsView" owner:self options:nil] objectAtIndex:0];
        // now add the view to ourselves...
        [xibView setFrame:[self bounds]];
        [self addSubview:xibView];
        
        return xibView;
    }
    return self;
}

-(void)setup{
    self.loadingView.layer.cornerRadius= 5.0;
    [self.loadingView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    self.loadingView.opaque= NO;
    self.textLabel= translateString(@"loading_stations_data");
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
