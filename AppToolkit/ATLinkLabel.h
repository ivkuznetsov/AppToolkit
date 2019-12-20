//
//  ATLinkLabel.h
//  AppToolkit
//
//  Created by Ilya Kuznecov on 27/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATLinkLabel : UILabel

// NSAttributedString attributes
@property (nonatomic) NSDictionary *linkDefault UI_APPEARANCE_SELECTOR;
@property (nonatomic) NSDictionary *linkHighlight UI_APPEARANCE_SELECTOR;

- (void)setLinkForRange:(NSRange)range attributes:(NSDictionary *)attributes handler:(void(^)(NSRange))handler;
- (void)setLinkForRange:(NSRange)range handler:(void(^)(NSRange))handler;
- (void)setLinkForSubstring:(NSString *)substring attribute:(NSDictionary *)attribute handler:(void(^)(NSString *))handler;
- (void)setLinkForSubstring:(NSString *)substring handler:(void(^)(NSString *))handler;
- (void)setLinksForSubstrings:(NSArray *)substrings handler:(void(^)(NSString *))handler;
- (void)clearActions;

@end
