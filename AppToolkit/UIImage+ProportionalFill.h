//
//  UIImage+ProportionalFill.h
//

#import <UIKit/UIKit.h>

@interface UIImage (ProportionalFill)

typedef enum {
    ImageResizeCrop,	// analogous to UIViewContentModeScaleAspectFill, i.e. "best fit" with no space around.
    ImageResizeCropStart,
    ImageResizeCropEnd,
    ImageResizeScale	// analogous to UIViewContentModeScaleAspectFit, i.e. scale down to fit, leaving space around if necessary.
} ImageResizingMethod;

- (UIImage *)imageToFitSize:(CGSize)size method:(ImageResizingMethod)resizeMethod;
- (UIImage *)imageCroppedToFitSize:(CGSize)size; // uses ImageResizeCrop
- (UIImage *)imageScaledToFitSize:(CGSize)size; // uses ImageResizeScale

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage *)imageFromRect:(CGRect)rect;
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;

@end
