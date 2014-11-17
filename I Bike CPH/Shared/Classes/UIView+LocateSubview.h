//
//  UIView+LocateSubview.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 18/09/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * UIView category to find subviews of certain class
 */
@interface UIView (LocateSubview)

- (UIView*)subviewWithClassName:(NSString*) className;

@end
