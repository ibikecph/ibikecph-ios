//
//  UIImage+PathCropping.m
//  UIImageAdditions
//
//  Created by Manuel Meyer on 28.12.13.
//  Copyright (c) 2013 bit.fritze. All rights reserved.
//

#import "UIImage+PathCropping.h"
#import "UIImage+Resize.h"

@implementation UIImage (PathCropping)
-(UIImage *)imageCroppedWithPath:(UIBezierPath *)path
{
    
    return [self imageCroppedWithPath:path invertPath:NO];
}

-(UIImage *)imageCroppedWithPath:(UIBezierPath *)path
                      invertPath:(BOOL)invertPath
{
    float scaleFactor = [self scale];
    CGRect imageRect = CGRectMake(0, 0, self.size.width * scaleFactor, self.size.height *scaleFactor);
    
    CGColorSpaceRef colorSpace  = CGImageGetColorSpace(self.CGImage);
    CGContextRef context        = CGBitmapContextCreate(NULL,
                                                        imageRect.size.width,
                                                        imageRect.size.height ,
                                                        CGImageGetBitsPerComponent(self.CGImage),
                                                        0,
                                                        colorSpace,
                                                        (CGBitmapInfo)CGImageGetAlphaInfo(self.CGImage)
                                                        );
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, 0.0, self.size.height *scaleFactor);
    CGContextScaleCTM(context, 1.0 , -1.0);
    
    CGAffineTransform transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    [path applyTransform:transform];
    
    if(invertPath){
        UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:imageRect];
        CGContextAddPath(context, rectPath.CGPath);
        CGContextAddPath(context, path.CGPath);
        CGContextEOClip(context);
    } else {
        CGContextAddPath(context, path.CGPath);
        CGContextClip(context);
    }
    
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0.0, -self.size.height * scaleFactor);

    CGContextDrawImage(context, imageRect, [self CGImage]);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    return [UIImage imageWithCGImage:imageRef scale:scaleFactor orientation:0];
}
@end
