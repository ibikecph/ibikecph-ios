//
//  SMAddressPickerView.h
//  I Bike CPH
//
//  Created by Nikola Markovic on 7/12/13.
//  Copyright (c) 2013 City of Copenhagen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum  {
    AddressTypeUndefined= -1,
    AddressTypeSource = 0,
    AddressTypeDestination = 1
}AddressType;

@class SMAddressPickerView;

@protocol AddressSelectDelegate <NSObject>

-(void)addressView:(SMAddressPickerView*)pAddressPickerView didSelectItemAtIndex:(int)index forAddressType:(AddressType)pAddressType;
-(NSString*)addressView:(SMAddressPickerView *)pAddressPickerView titleForRow:(int)row;
@end

/**
 * Address picker view. Loads SMAddressPickerView.xib. Used in SMBreakRouteViewController.
 */
@interface SMAddressPickerView : UIView<UIPickerViewDelegate> // FIXME: Don't expose UIPickerViewDelegate

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (assign, nonatomic) AddressType addressType;
@property (weak, nonatomic) id<AddressSelectDelegate> delegate;
@property (assign, nonatomic) NSInteger sourceCurrentIndex;
@property (assign, nonatomic) NSInteger destinationCurrentIndex;

- (IBAction)didTapOnCancel:(id)sender;
- (IBAction)didTapOnDone:(id)sender;

-(void)displayAnimated;
-(void)hideAnimated;
@end
