//
//  SMAddressPickerView.m
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import "SMAddressPickerView.h"

#define PICKER_BOTTOM_MARGIN 25.0
#define ANIMATION_DISPLAY_DURATION 0.3
#define ANIMATION_HIDE_DURATION 0.3

@interface SMAddressPickerView ()
@property (nonatomic) NSInteger tempIndex;
@end

@implementation SMAddressPickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    SMAddressPickerView *xibView = [[[NSBundle mainBundle] loadNibNamed:@"SMAddressPickerView" owner:self options:nil] objectAtIndex:0];
    if (xibView) {
        [xibView setFrame:frame];
        [xibView setup];
        self = xibView;
    }

    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.opaque = YES;

    self.addressType = AddressTypeUndefined;

    self.sourceCurrentIndex = 0;
    self.destinationCurrentIndex = 0;
}

- (IBAction)didTapOnCancel:(id)sender
{
    [self hideAnimated];
}

- (IBAction)didTapOnDone:(id)sender
{
    [self setIndex:self.tempIndex];
    [self.delegate addressView:self didSelectItemAtIndex:[self index] forAddressType:self.addressType];

    [self hideAnimated];
}

- (void)displayAnimated
{
    NSAssert(self.addressType != AddressTypeUndefined, @"AddressType not set");
    [self resetTempIndex];
    [self.pickerView selectRow:[self index] inComponent:0 animated:NO];
    [self.pickerView reloadAllComponents];
    [UIView animateWithDuration:ANIMATION_DISPLAY_DURATION
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       CGRect frm = self.frame;
                       float viewHeight = self.pickerView.frame.origin.y + self.pickerView.frame.size.height + PICKER_BOTTOM_MARGIN - 64;
                       frm.origin.y = self.superview.frame.size.height - viewHeight - 32;
                       self.frame = frm;
                     }
                     completion:nil];
}

- (void)hideAnimated
{
    [UIView animateWithDuration:ANIMATION_HIDE_DURATION
        delay:0.0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{
          CGRect frm = self.frame;
          frm.origin.y = self.superview.frame.size.height;
          self.frame = frm;
        }
        completion:^(BOOL animated) {
          self.addressType = AddressTypeUndefined;
        }];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.delegate addressView:self titleForRow:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.tempIndex = row;
}

- (NSInteger)index
{
    NSAssert(self.addressType != AddressTypeUndefined, @"Address Type is undefined");
    if (self.addressType == AddressTypeDestination)
        return self.destinationCurrentIndex;
    else if (self.addressType == AddressTypeSource) {
        return self.sourceCurrentIndex;
    }

    return -1;
}

- (void)resetTempIndex
{
    if (self.addressType == AddressTypeDestination) {
        self.tempIndex = self.destinationCurrentIndex;
    }
    else if (self.addressType == AddressTypeSource) {
        self.tempIndex = self.sourceCurrentIndex;
    }
}
- (void)setIndex:(NSInteger)index
{
    NSAssert(self.addressType != AddressTypeUndefined, @"Address Type is undefined");
    if (self.addressType == AddressTypeDestination)
        self.destinationCurrentIndex = index;
    else if (self.addressType == AddressTypeSource) {
        self.sourceCurrentIndex = index;
    }
}
@end
