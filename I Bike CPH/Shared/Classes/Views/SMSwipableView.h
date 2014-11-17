//
//  SMSwipableView.h
//  iBike
//
//  Created by Ivan Pavlovic on 27/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMTurnInstruction.h"

/**
 * View to display a direction instruction. Has description label (not used), direction image, distance label, wayname label Has convenience function to load from SMSwipableView.xib
 */
@interface SMSwipableView : UIView

@property (weak, nonatomic) IBOutlet UILabel *lblDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imgDirection;
@property (weak, nonatomic) IBOutlet UILabel *lblDistance;
@property (weak, nonatomic) IBOutlet UILabel *lblWayname;

@property NSInteger position;

+ (SMSwipableView*) getFromNib;

- (void)renderViewFromInstruction:(SMTurnInstruction *)turn;

+ (CGFloat)getHeight;

@end
