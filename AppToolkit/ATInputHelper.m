//
//  ATInputHelper.m
//  AppToolkit
//
//  Created by Ilya Kuznecov on 27/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import "ATInputHelper.h"

@interface ATInputHelper() <UIGestureRecognizerDelegate>

@end

@implementation ATInputHelper

- (instancetype)initWithScrollView:(UIScrollView *)scrollView delegate:(id<ATInputHelperDelegate>)delegate {
    if (self = [self init]) {
        self.scrollView = scrollView;
        self.delegate = delegate;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (UITapGestureRecognizer *)tapGR {
    if (!_tapGR) {
        _tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        _tapGR.delegate = self;
        _tapGR.cancelsTouchesInView = NO;
        _tapGR.enabled = NO;
    }
    return _tapGR;
}

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    [_scrollView addGestureRecognizer:self.tapGR];
}

- (void)tapAction:(UITapGestureRecognizer *)gr {
    [self.scrollView.superview endEditing:YES];
}

- (void)unselectInput:(id)input {
    if ([input isKindOfClass:[UITextField class]]) {
        [input removeTarget:self action:@selector(nextAction:) forControlEvents:UIControlEventEditingDidEndOnExit];
        [input removeTarget:self action:@selector(inputDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    if ([input respondsToSelector:@selector(setDidChange:)]) {
        [input setDidChange:nil];
    }
    if ([input respondsToSelector:@selector(setDidSelectNext:)]) {
        [input setDidSelectNext:nil];
    }
}

- (void)selectInput:(id)input isLast:(BOOL)isLast {
    __weak typeof(self) wSelf = self;
    __weak typeof(input) wInput = input;
    
    if ([input isKindOfClass:[UITextField class]]) {
        [input addTarget:self action:@selector(nextAction:) forControlEvents:UIControlEventEditingDidEndOnExit];
        [input addTarget:self action:@selector(inputDidChange:) forControlEvents:UIControlEventEditingChanged];
        [input setReturnKeyType:UIReturnKeyNext];
        if (isLast) {
            [input setReturnKeyType:UIReturnKeyDone];
        }
    }
    if ([input respondsToSelector:@selector(setDidChange:)]) {
        [input setDidChange:^{
            [wSelf inputDidChange:wInput];
        }];
    }
    if ([input respondsToSelector:@selector(setDidSelectNext:)]) {
        [input setDidSelectNext:^{
            [wSelf nextAction:wInput];
        }];
    }
}

- (void)setInputs:(NSArray *)inputs {
    for (id input in _inputs) {
        if ([input isKindOfClass:[NSArray class]]) {
            for (id innerInput in input) {
                [self unselectInput:innerInput];
            }
        } else {
            [self unselectInput:input];
        }
    }
    _inputs = inputs;
    
    for (id input in _inputs) {
        if ([input isKindOfClass:[NSArray class]]) {
            for (id innerInput in input) {
                [self selectInput:innerInput isLast:[input lastObject] == innerInput];
            }
        } else {
            [self selectInput:input isLast:_inputs.lastObject == input];
        }
    }
}

- (void)didChangeTextView:(NSNotification *)notificaiton {
    for (id input in _inputs) {
        if ([input isKindOfClass:[NSArray class]]) {
            if ([input containsObject:notificaiton.object]) {
                [self inputDidChange:notificaiton.object];
                break;
            }
        } else if (input == notificaiton.object) {
            [self inputDidChange:notificaiton.object];
            break;
        }
    }
}

- (void)inputDidChange:(id)input {
    if ([input respondsToSelector:@selector(setValidationFailed:)]) {
        [input setValidationFailed:NO];
    }
}

- (void)nextAction:(id)sender {
    NSArray *array = nil;
    
    if ([_inputs containsObject:sender]) {
        array = _inputs;
    } else {
        for (NSArray *input in _inputs) {
            if ([input isKindOfClass:[NSArray class]]) {
                if ([input containsObject:sender]) {
                    array = input;
                    break;
                }
            }
        }
    }
    
    NSUInteger index = [array indexOfObject:sender];
    if (index == array.count - 1) {
        [self trySubmit:self];
    } else {
        index++;
        UIView *nextResponder = array[index];
        [nextResponder becomeFirstResponder];
        
        if ([_delegate respondsToSelector:@selector(scrollToInput:)]) {
            [_delegate scrollToInput:nextResponder];
        }
    }
}

- (BOOL)validateInput:(UIView<ValidatableInput> *)input {
    BOOL currentResult = [_delegate isInputValid:input];
    
    if ([input respondsToSelector:@selector(setValidationFailed:)]) {
        input.validationFailed = !currentResult;
    }
    return currentResult;
}

- (BOOL)validateInputs:(NSUInteger)index {
    BOOL result = YES;
    UIView *firstFailedInput = nil;
    if ([_delegate respondsToSelector:@selector(isInputValid:)]) {
        BOOL currentResult = NO;
        NSArray *input = _inputs[index];
        
        for (UIView<ValidatableInput> *innerInput in input) {
            currentResult = [self validateInput:innerInput];
            
            if (result) {
                result = currentResult;
            }
            if (!currentResult && !firstFailedInput) {
                firstFailedInput = innerInput;
            }
        }
    }
    if (firstFailedInput) {
        [_scrollView scrollRectToVisible:[_scrollView convertRect:firstFailedInput.bounds fromView:firstFailedInput] animated:YES];
    }
    return result;
}

- (BOOL)validateInputs {
    BOOL result = YES;
    UIView *firstFailedInput = nil;
    if ([_delegate respondsToSelector:@selector(isInputValid:)]) {
        for (id input in _inputs) {
            BOOL currentResult = NO;
            
            if ([input isKindOfClass:[NSArray class]]) {
                for (UIView<ValidatableInput> *innerInput in input) {
                    currentResult = [self validateInput:innerInput];
                    
                    if (result) {
                        result = currentResult;
                    }
                    if (!currentResult && !firstFailedInput) {
                        firstFailedInput = innerInput;
                    }
                }
            } else {
                currentResult = [self validateInput:input];
                
                if (result) {
                    result = currentResult;
                }
                if (!currentResult && !firstFailedInput) {
                    firstFailedInput = input;
                }
            }
        }
    }
    if (firstFailedInput) {
        [_scrollView scrollRectToVisible:[_scrollView convertRect:firstFailedInput.bounds fromView:firstFailedInput] animated:YES];
    }
    return result;
}

- (IBAction)trySubmit:(id)sender {
    [self.scrollView.superview endEditing:YES];
    
    if ([_delegate respondsToSelector:@selector(didSuccessInput)] && [self validateInputs]) {
        [_delegate didSuccessInput];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat bottomOffset = 0;
    if (keyboardFrame.origin.y + keyboardFrame.size.height >= [UIScreen mainScreen].bounds.size.height) {
        bottomOffset = [UIScreen mainScreen].bounds.size.height - keyboardFrame.origin.y;
        UIView *topView = _scrollView.superview;
        
        while (topView.superview) {
            topView = topView.superview;
        }
        CGRect viewRect = [_scrollView convertRect:_scrollView.bounds toView:topView];
        CGFloat viewBottomOffset = [UIScreen mainScreen].bounds.size.height - (viewRect.origin.y + viewRect.size.height);
        
        viewBottomOffset += _scrollView.safeAreaInsets.bottom;
                
        bottomOffset = MAX(0, bottomOffset - viewBottomOffset);
    }
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationDuration:duration];
    
    CGFloat insetOffset = (bottomOffset + _additionalBottomInset) - _scrollView.contentInset.bottom;
    
    if (insetOffset < 0) {
        CGPoint point = _scrollView.contentOffset;
        
        if (_autoscrollBottom) {
            point.y += insetOffset;
            point.y = point.y;
        }
        if ([_delegate respondsToSelector:@selector(targetOffsetOnKeyboardHide:input:)]) {
            point.y = [_delegate targetOffsetOnKeyboardHide:point.y input:[self currentResponder]];
        }
        if (point.y != _scrollView.contentOffset.y) {
            _scrollView.contentOffset = point;
        }
    }
    
    UIEdgeInsets insets = _scrollView.contentInset;
    insets.bottom = bottomOffset + _additionalBottomInset;
    if ([_delegate respondsToSelector:@selector(customInsets:)]) {
        insets = [_delegate customInsets:insets];
    }
    _scrollView.contentInset = insets;
    
    insets = _scrollView.scrollIndicatorInsets;
    insets.bottom = bottomOffset + _additionalBottomInset;
    
    _scrollView.scrollIndicatorInsets = insets;
    
    if ([_delegate respondsToSelector:@selector(animateInsetChangeWithInsets:)]) {
        UIEdgeInsets insets = _scrollView.contentInset;
        insets.bottom -= _additionalBottomInset;
        
        [_scrollView layoutIfNeeded];
        CGPoint offset = _scrollView.contentOffset;
        [_delegate animateInsetChangeWithInsets:insets];
        _scrollView.contentOffset = offset;
    }
    
    if (insetOffset > 0) {
        CGPoint point = _scrollView.contentOffset;
        if (_autoscrollBottom) {
            point.y += MAX(0, insetOffset - MAX(0, (_scrollView.frame.size.height - _scrollView.safeAreaInsets.top - _scrollView.safeAreaInsets.bottom - _scrollView.contentSize.height - _additionalBottomInset - _scrollView.contentInset.top)));
        }
        if ([_delegate respondsToSelector:@selector(targetOffsetOnKeyboardShow:input:insets:)]) {
            point.y = [_delegate targetOffsetOnKeyboardShow:point.y input:[self currentResponder] insets:_scrollView.contentInset];
        }
        if (point.y != _scrollView.contentOffset.y) {
            _scrollView.contentOffset = point;
        }
    }
    self.tapGR.enabled = bottomOffset != 0;
    
    if (bottomOffset != 0 && [_delegate respondsToSelector:@selector(scrollToInput:)]) {
        [_delegate scrollToInput:self.currentResponder];
    }
    
    [UIView commitAnimations];
}

- (UIView *)currentResponder {
    for (id input in _inputs) {
        if ([input isKindOfClass:[NSArray class]]) {
            for (UIView *responder in input) {
                if ([responder isFirstResponder]) {
                    return responder;
                }
            }
        } else if ([input isFirstResponder]) {
            return input;
        }
    }
    return nil;
}

- (void)setAdditionalBottomInset:(CGFloat)additionalBottomInset {
    CGFloat offset = _additionalBottomInset - additionalBottomInset;
    _additionalBottomInset = additionalBottomInset;
    
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.y -= offset;
    self.scrollView.contentOffset = contentOffset;
    
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom -= offset;
    self.scrollView.contentInset = insets;
    insets = self.scrollView.scrollIndicatorInsets;
    insets.bottom -= offset;
    self.scrollView.scrollIndicatorInsets = insets;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        return NO;
    }
    if (touch.view.isFirstResponder) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
