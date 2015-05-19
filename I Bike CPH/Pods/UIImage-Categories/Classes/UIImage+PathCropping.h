//
//  UIImage+PathCropping.h
//  UIImageAdditions
//
//  Created by Manuel Meyer on 28.12.13.
//  Copyright (c) 2013 bit.fritze. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (PathCropping)

/**
 *  crop receiver with a given path
 *
 *  @param path the path that is used for cropping. Must be non-nil.
 *
 *  @return the cropped image
 */
-(UIImage *)imageCroppedWithPath:(UIBezierPath *)path;

/**
 *  crop receiver with a given path
 *
 *  @param path the path that is used for cropping. Must be non-nil.
 *
 * @param invertedPath if YES the path will be inverted
 *
 *  @return the cropped image
 */
-(UIImage *)imageCroppedWithPath:(UIBezierPath *)path invertPath:(BOOL) invertPath;

@end
