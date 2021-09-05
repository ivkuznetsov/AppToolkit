//
//  ATInputHelper.h
//  AppToolkit
//
//  Created by Ilya Kuznecov on 27/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// You can use this protocol to higlight invalid items
@protocol ValidatableInput <NSObject>

@property (nonatomic) BOOL validationFailed;

// these methods aren't needed for subclasses of UITextField and UITextView
@optional
@property (nonatomic) dispatch_block_t didChange;
@property (nonatomic) dispatch_block_t didSelectNext;

@end

@protocol ATInputHelperDelegate <NSObject>

@optional
- (void)didSuccessInput;
- (BOOL)isInputValid:(UIView *)input;
- (UIEdgeInsets)customInsets:(UIEdgeInsets)originalInsets; // performed in animation block
- (void)animateInsetChangeWithInsets:(UIEdgeInsets)insets; // performed in animation block
- (CGFloat)targetOffsetOnKeyboardHide:(CGFloat)originalOffset input:(UIView *)input;
- (CGFloat)targetOffsetOnKeyboardShow:(CGFloat)originalOffset input:(UIView *)input insets:(UIEdgeInsets)insets;
- (void)scrollToInput:(UIView *)input; // use it when your texfield in UITableViewCell

@end

@interface ATInputHelper : NSObject

@property (nonatomic) UITapGestureRecognizer *tapGR;
@property (nonatomic) IBOutletCollection(UIView) NSArray* inputs; // Can be NSArray<UIView> or NSArray<NSArray<UIView>>
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet id<ATInputHelperDelegate> delegate;
@property (nonatomic) IBInspectable BOOL autoscrollBottom; // if you want to attach content offset to the bottom of visible area when keyboard appears
@property (nonatomic) CGFloat additionalBottomInset;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView delegate:(id<ATInputHelperDelegate>)delegate;
- (IBAction)trySubmit:(id)sender;
- (BOOL)validateInputs;
- (BOOL)validateInputs:(NSUInteger)index; // if you use NSArray<NSArray> in inputs

@end
