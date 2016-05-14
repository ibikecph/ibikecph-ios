@import UIKit;

@interface UIColor (Hex)

/**
 *  Create a color from a hex value represented as a string.
 *
 *  @param hexString    The string representing the hex value. The format is "(#)rrggbb".
 *  @param alpha        The alpha value of the created color.
 *
 *  @return The created color.
 */
+ (UIColor *)hex_colorFromStringWithHexRGBValue:(NSString *)hexString alpha:(float)alpha;

@end