//
//  UIImage+Grayscale.h
//  UIImageAdditions
//
//  Created by Manuel Meyer on 28.12.13.
//  Copyright (c) 2013 bit.fritze. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Grayscale)

/**
 *  Return a grayscale version of the receiving image
 *
 *  @return the grayscaled image. 
 */
- (UIImage *)grayscaledImage;
@end
