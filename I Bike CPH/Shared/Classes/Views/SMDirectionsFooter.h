//
//  SMDirectionsFooter.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 02/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMUtil.h"

/**
 * View for "Report a problem" when ending route. Acts as button. Has convenience function that Loads from SMDirectionsFooter.xib.
 */
@interface SMDirectionsFooter : UIView

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (nonatomic, weak) id<ViewTapDelegate>delegate;

+ (CGFloat)getHeight;
+ (SMDirectionsFooter*) getFromNib;

@end
