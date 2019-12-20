//
//  UIImage+ProportionalFill.m
//

#import "UIImage+ProportionalFill.h"

@implementation UIImage (ProportionalFill)

- (CGFloat)fillScaleFactorForFitSize:(CGSize)fitSize {
    CGFloat scaleFactorX = fitSize.width / self.size.width;
    CGFloat scaleFactorY = fitSize.height / self.size.height;
    
    return MAX(scaleFactorX, scaleFactorY);
}

- (CGFloat)fillCropOffsetMiltiplier:(ImageResizingMethod)resizeMethod {
    if (resizeMethod == ImageResizeCropEnd) {
        return 0.0f;
    }
    else if (resizeMethod == ImageResizeCrop) {
        return -0.5f;
    }
    else if (resizeMethod == ImageResizeCropStart) {
        return -1.0f;
    }
    return 0.0f;
}

- (CGFloat)fitScaleFactorForFitSize:(CGSize)fitSize {
    CGFloat scaleFactorX = fitSize.width / self.size.width;
    CGFloat scaleFactorY = fitSize.height / self.size.height;

    return MIN(scaleFactorX, scaleFactorY);
}

- (UIImage *)imageToFitSize:(CGSize)fitSize method:(ImageResizingMethod)resizeMethod {
    
    CGSize destinationSize;
    CGRect drawRect;
    
    if (resizeMethod == ImageResizeCropStart ||
        resizeMethod == ImageResizeCrop ||
        resizeMethod == ImageResizeCropEnd) {
        
        CGFloat scaleFactor = [self fillScaleFactorForFitSize:fitSize];
        CGFloat offsetMultiplier = [self fillCropOffsetMiltiplier:resizeMethod];
        
        drawRect.size = CGSizeMake(self.size.width * scaleFactor, self.size.height * scaleFactor);
        drawRect.origin = CGPointMake(offsetMultiplier * (drawRect.size.width - fitSize.width), offsetMultiplier * (drawRect.size.height - fitSize.height));
        
        destinationSize = fitSize;
    }
    else if (resizeMethod == ImageResizeScale) {
        CGFloat scaleFactor = [self fitScaleFactorForFitSize:fitSize];
        
        drawRect.size = CGSizeMake(ceilf(self.size.width * scaleFactor), (int)(self.size.height * scaleFactor));
        drawRect.origin = CGPointZero;
        
        destinationSize = drawRect.size;
    }
    else {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(destinationSize, NO, self.scale);
    [self drawInRect:drawRect];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (UIImage *)imageCroppedToFitSize:(CGSize)fitSize {
    return [self imageToFitSize:fitSize method:ImageResizeCrop];
}

- (UIImage *)imageScaledToFitSize:(CGSize)fitSize {
    return [self imageToFitSize:fitSize method:ImageResizeScale];
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize {
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor) {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil)
        UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage*)imageFromRect:(CGRect) rect {
    CGRect newRect;
    newRect.origin.x = rect.origin.x * [[UIScreen mainScreen] scale];
    newRect.origin.y = rect.origin.y * [[UIScreen mainScreen] scale];
    newRect.size.width = rect.size.width * [[UIScreen mainScreen] scale];
    newRect.size.height = rect.size.height * [[UIScreen mainScreen] scale];
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], newRect);
    // or use the UIImage wherever you like
    UIImage* image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return image;
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees {
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI/180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, degrees * M_PI/180);
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
