//
//  UIImage+Grayscale.m
//  UIImageAdditions
//
//  Created by Manuel Meyer on 28.12.13.
//  Copyright (c) 2013 bit.fritze. All rights reserved.
//

#import "UIImage+Grayscale.h"

@implementation UIImage (Grayscale)

- (UIImage *)grayscaledImage
{
    float scaleFactor = [self scale];
    CGRect imageRect = CGRectMake(0, 0, self.size.width * scaleFactor, self.size.height *scaleFactor);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 self.size.width * scaleFactor,
                                                 self.size.height * scaleFactor,
                                                 8,
                                                 0,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNone);
    CGContextSaveGState(context);
    
    CGContextDrawImage(context, imageRect, [self CGImage]);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    CGContextRestoreGState(context);

    return [UIImage imageWithCGImage:imageRef scale:scaleFactor orientation:0];
}
@end
