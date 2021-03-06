//
//  SMCustomButton.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 16/04/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Button to handle resize of text in title label.
 */
@interface SMCustomButton : UIButton

-(void) resizeToFitTheTextWithMinWidth:(float)minWidth andMaxWidth:(float) maxWidth;

@end
