//
//  ATPreviewScrollView.h
//  AppToolkit
//
//  Created by Ilya Kuznecov on 27/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATPreviewScrollView : UIScrollView

@property (nonatomic) IBInspectable BOOL aspectFill;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) void(^didZoom)(CGFloat zoom);
@property (nonatomic) void(^didScroll)(void);
@property (nonatomic) void(^didEndScroll)(void);
@property (nonatomic) void(^didZoomContinuus)(void);
@property (nonatomic) NSNumber *minAspectLimit;
@property (nonatomic) NSNumber *maxAspectLimit;

- (void)setImage:(UIImage *)image;
- (UIImage *)croppedImage;
- (void)zoomToFill;
- (CGRect)croppingRect;
- (void)setCropRect:(CGRect)rect;

@end
