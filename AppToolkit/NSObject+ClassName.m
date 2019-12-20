//
//  NSObject+ClassName.m
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

#import "NSObject+ClassName.h"
#import <objc/runtime.h>

@implementation NSObject (ClassName)

- (NSString *)className {
	return [NSString stringWithUTF8String:class_getName(self.class)];
}

+ (NSString *)className {
	return [NSString stringWithUTF8String:class_getName(self)];
}

@end
