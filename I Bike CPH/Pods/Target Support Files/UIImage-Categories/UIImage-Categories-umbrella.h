#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIImage+Alpha.h"
#import "UIImage+Grayscale.h"
#import "UIImage+PathCropping.h"
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"

FOUNDATION_EXPORT double UIImage_CategoriesVersionNumber;
FOUNDATION_EXPORT const unsigned char UIImage_CategoriesVersionString[];

