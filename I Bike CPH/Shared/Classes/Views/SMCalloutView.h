//
//  SMCalloutView.h
//  I Bike CPH
//
//  Created by Ivan Pavlovic on 04/02/2013.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SMCalloutDelegate <NSObject>
- (void)buttonClicked;
@end

/**
 * View as pop up box. Has text label, description label, and button. Used in SMAnnotation. FIXME: Merge.
 */
@interface SMCalloutView : UIView  {
}

@property (nonatomic, weak) id<SMCalloutDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *calloutLabel;
@property (weak, nonatomic) IBOutlet UILabel *calloutSublabel;
@property (weak, nonatomic) IBOutlet UIButton *calloutButton;

@property (weak, nonatomic) IBOutlet UIImageView *bgLeft;
@property (weak, nonatomic) IBOutlet UIImageView *bgMiddle;
@property (weak, nonatomic) IBOutlet UIImageView *bgRight;
@property (weak, nonatomic) IBOutlet UIImageView *markerIcon;
@property (weak, nonatomic) IBOutlet UIImageView *markerIcon2;

+ (SMCalloutView*) getFromNib;
+ (CGFloat)getHeight;

@end
