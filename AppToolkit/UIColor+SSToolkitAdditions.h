//
//  UIColor+SSToolkitAdditions.h
//  SSToolkit
//
//  Created by Sam Soffes on 4/19/10.
//  Copyright 2010-2011 Sam Soffes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SSToolkitAdditions)

@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;
@property (nonatomic, readonly) CGFloat alpha;

+ (UIColor *)colorWithHex:(NSString *)hex;
- (NSString *)hexValue;
- (NSString *)hexValueWithAlpha:(BOOL)includeAlpha;

@end
