#import <UIKit/UIKit.h>

@interface UIImage (Tint)

- (UIImage *)imageTintedWithColor:(UIColor *)color;
- (UIImage *)imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction;
- (UIImage *)imageConvertedToGrayScale;

@end
