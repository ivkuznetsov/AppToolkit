//
//  UIColor+SSToolkitAdditions.h
//  SSToolkit
//
//  Created by Sam Soffes on 4/19/10.
//  Copyright 2010-2011 Sam Soffes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SSToolkitAdditions)

@property (nonatomic, readonly) CGFloat redValue;
@property (nonatomic, readonly) CGFloat greenValue;
@property (nonatomic, readonly) CGFloat blueValue;
@property (nonatomic, readonly) CGFloat alphaValue;

+ (UIColor *)colorWithHex:(NSString *)hex;
- (NSString *)hexValue;
- (NSString *)hexValueWithAlpha:(BOOL)includeAlpha;

@end
