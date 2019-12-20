//
//  ATReusableView.m
//  AppToolkit
//
//  Created by Ilya Kuznecov on 27/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import "ATReusableView.h"

@interface ATReusableView()

@property (nonatomic) IBInspectable NSString *nibName;

@end

@implementation ATReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    UIView *view = nil;
    
    for (UIView *object in [[NSBundle mainBundle] loadNibNamed:_nibName ?: [NSStringFromClass(self.class) componentsSeparatedByString:@"."].lastObject owner:self options:nil]) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    view.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:view atIndex:0];
    self.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0);
}

@end
