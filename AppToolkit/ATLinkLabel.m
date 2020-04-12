//
//  ATLinkLabel.m
//  AppToolkit
//
//  Created by Ilya Kuznecov on 27/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import "ATLinkLabel.h"

@interface ATLinkLabel()

@property (nonatomic) NSMutableDictionary *handlerDictionary;
@property (nonatomic) NSLayoutManager *layoutManager;
@property (nonatomic) NSTextContainer *textContainer;
@property (nonatomic) NSAttributedString *backupAttributedText;
@property (nonatomic) NSMutableSet *defaultRanges;
@property (nonatomic) UIFont *originalFont;

@end

@implementation ATLinkLabel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self checkInitialization];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self checkInitialization];
    }
    return self;
}

- (void)checkInitialization {
    _originalFont = self.font;
    _handlerDictionary = [NSMutableDictionary new];
    _defaultRanges = [NSMutableSet set];
  //  self.lineBreakMode = NSLineBreakByWordWrapping;
    
    if (!self.userInteractionEnabled) {
        self.userInteractionEnabled = YES;
    }
}

- (void)setLinkDefault:(NSDictionary *)linkDefault {
    _linkDefault = linkDefault;
    
    if (linkDefault) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        for (NSValue *range in _defaultRanges) {
            [attributedString addAttributes:linkDefault range:range.rangeValue];
        }
        self.attributedText = attributedString;
    }
}

- (void)setLinkForRange:(NSRange)range attributes:(NSDictionary *)attributes handler:(void(^)(NSRange))handler {
    [self setLinkForRange:range attributes:attributes handler:handler defaultAttributes:NO];
}

- (void)setLinkForRange:(NSRange)range attributes:(NSDictionary *)attributes handler:(void(^)(NSRange))handler defaultAttributes:(BOOL)defaultAttributes {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    
    if (attributes) {
        [attributedString addAttributes:attributes range:range];
    } else {
        [attributedString addAttributes:@{ NSUnderlineStyleAttributeName : @1 } range:range];
    }
    if (handler) {
        [self.handlerDictionary setObject:handler forKey:[NSValue valueWithRange:range]];
    }
    if (defaultAttributes) {
        [_defaultRanges addObject:[NSValue valueWithRange:range]];
    }
    self.attributedText = attributedString;
}

- (void)setLinkForSubstring:(NSString *)substring attribute:(NSDictionary *)attribute handler:(void(^)(NSString *))handler {
    NSRange range = [self.attributedText.string rangeOfString:substring];
    if (range.length) {
        [self setLinkForRange:range attributes:attribute handler:^(NSRange range){
            handler(substring);
        } defaultAttributes:NO];
    }
}

- (void)setLinkForRange:(NSRange)range handler:(void(^)(NSRange))handler {
    [self setLinkForRange:range attributes:_linkDefault handler:handler defaultAttributes:YES];
}

- (void)setLinkForSubstring:(NSString *)substring handler:(void(^)(NSString *))handler {
    NSRange range = [self.attributedText.string rangeOfString:substring];
    if (range.length) {
        [self setLinkForRange:range attributes:_linkDefault handler:^(NSRange range) {
            handler(substring);
        } defaultAttributes:YES];
    }
}

- (void)setLinksForSubstrings:(NSArray *)substrings handler:(void(^)(NSString *))handler {
    for (NSString *linkString in substrings) {
        [self setLinkForSubstring:linkString handler:handler];
    }
}

- (void)setFont:(UIFont *)font {
    _originalFont = font;
    [super setFont:font];
}

- (void)setText:(NSString *)text {
    [self clearActions];
    [super setText:text];
}
    
- (void)clearActions {
    [super setFont:_originalFont];
    [_handlerDictionary removeAllObjects];
    [_defaultRanges removeAllObjects];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.backupAttributedText = self.attributedText;
    for (UITouch *touch in touches) {
        CGPoint touchPoint = [touch locationInView:self];
        NSValue *rangeValue = [self attributedTextRangeForPoint:touchPoint];
        if (rangeValue) {
            NSRange range = [rangeValue rangeValue];
            range.location = MIN(self.attributedText.length - 1, range.location);
            range.length = MIN(self.attributedText.length - range.location, range.length);
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
            
            if (_linkHighlight) {
                [attributedString addAttributes:_linkHighlight range:range];
            } else {
                [attributedString addAttributes:@{ NSForegroundColorAttributeName : [self.textColor colorWithAlphaComponent:0.5] } range:range];
            }
            [UIView transitionWithView:self duration:0.15 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                self.attributedText = attributedString;
            } completion:nil];
        }
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL result = [super pointInside:point withEvent:event];
    if (result) {
        NSValue *rangeValue = [self attributedTextRangeForPoint:point];
        return rangeValue != nil;
    }
    return NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [UIView transitionWithView:self duration:0.15 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.attributedText = self.backupAttributedText;
    } completion:nil];
    
    for (UITouch *touch in touches) {
        NSValue *rangeValue = [self attributedTextRangeForPoint:[touch locationInView:self]];
        if (rangeValue) {
            void(^handler)(NSRange) = _handlerDictionary[rangeValue];
            handler([rangeValue rangeValue]);
        }
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [UIView transitionWithView:self duration:0.15 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.attributedText = self.backupAttributedText;
    } completion:nil];
}

- (NSValue *)attributedTextRangeForPoint:(CGPoint)point {
    NSLayoutManager *layoutManager = [NSLayoutManager new];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
    
    textContainer.lineFragmentPadding = 0.0;
    textContainer.lineBreakMode = self.lineBreakMode;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    textContainer.size = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
    [layoutManager addTextContainer:textContainer];
    
    //textStorage to calculate the position
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    [textStorage addLayoutManager:layoutManager];
    
    // find the tapped character location and compare it to the specified range
    CGPoint locationOfTouchInLabel = point;
    CGRect textBoundingBox = [layoutManager usedRectForTextContainer:textContainer];
    
    CGPoint textContainerOffset = CGPointZero;
    
    if (self.textAlignment == NSTextAlignmentCenter) {
        textContainerOffset = CGPointMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(textBoundingBox)) * 0.5 - CGRectGetMinX(textBoundingBox),
                                          (CGRectGetHeight(self.bounds) - CGRectGetHeight(textBoundingBox)) * 0.5 - CGRectGetMinY(textBoundingBox));
    } else {
        textContainerOffset = CGPointMake(0, (CGRectGetHeight(self.bounds) - CGRectGetHeight(textBoundingBox)) * 0.5 - CGRectGetMinY(textBoundingBox));
    }
    CGPoint locationOfTouchInTextContainer = CGPointMake(locationOfTouchInLabel.x - textContainerOffset.x, locationOfTouchInLabel.y - textContainerOffset.y);
    NSInteger indexOfCharacter = [layoutManager characterIndexForPoint:locationOfTouchInTextContainer inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    
    for (NSValue *rangeValue in _handlerDictionary) {
        NSRange range = [rangeValue rangeValue];
        if (NSLocationInRange(indexOfCharacter, range)) {
            return rangeValue;
        }
    }
    return nil;
}

@end
