//
//  SMStationPickerVIew.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/10/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * Station picker view wraps a UIPickerView with padding. Used in SMBreakRouteViewController
 */
@interface SMStationPickerView : UIView

@property(nonatomic, strong) UIPickerView* pickerView;

@end
