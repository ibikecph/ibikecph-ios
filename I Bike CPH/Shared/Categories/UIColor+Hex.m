#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)hex_colorFromStringWithHexRGBValue:(NSString *)hexString alpha:(float)alpha
{
    NSString *trimmedString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    uint32_t hex;

    NSScanner *scanner = [NSScanner scannerWithString:trimmedString];
    [scanner scanHexInt:&hex];
    
    uint32_t r = 0xff;
    uint32_t g = 0xff;
    uint32_t b = 0xff;

    r = (hex & 0xff0000) >> 8 * 2;
    g = (hex & 0x00ff00) >> 8 * 1;
    b = (hex & 0x0000ff);

    UIColor *newColor = [UIColor colorWithRed:(float)r / 255.0f green:(float)g / 255.0f blue:(float)b / 255.0f alpha:alpha];

    return newColor;
}

@end