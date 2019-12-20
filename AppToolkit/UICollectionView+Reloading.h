//
//  UICollectionView+Reloading.h
//  AppToolkit
//
//  Created by Ilya Kuznecov on 26/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (Reloading)

- (NSArray<NSIndexPath *> *)reloadAnimated:(BOOL)animated oldData:(NSArray *)oldData data:(NSArray *)data completion:(dispatch_block_t)completion updateObjects:(dispatch_block_t)updateObjects;

@end
