//
//  UICollectionView+Reloading.m
//  AppToolkit
//
//  Created by Ilya Kuznecov on 26/01/2017.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

#import "UICollectionView+Reloading.h"

@implementation UICollectionView (Reloading)

- (void)printDuplicates:(NSArray *)array {
    NSMutableSet *allSet = [NSMutableSet set];
    
    for (id object in array) {
        if ([allSet containsObject:object]) {
            NSLog(@"found duplicated object %@", object);
        } else {
            [allSet addObject:object];
        }
    }
}

- (NSArray<NSIndexPath *> *)reloadAnimated:(BOOL)animated oldData:(NSArray *)oldData data:(NSArray *)data completion:(dispatch_block_t)completion updateObjects:(dispatch_block_t)updateObjects {
    BOOL applicationPresented = YES;
    
    if ([UIApplication respondsToSelector:@selector(sharedApplication)]) {
        UIApplication *sharedApplication = [UIApplication valueForKey:@"sharedApplication"];
        applicationPresented = sharedApplication.applicationState == UIApplicationStateActive;
    }
    
    if (!animated || !oldData.count || !self.window || !applicationPresented) {
        
        if (updateObjects) updateObjects();
        [self reloadData];
        [self layoutIfNeeded];
        if (completion) completion();
        return nil;
    }
    
    NSMutableArray *toAdd = [NSMutableArray array];
    NSMutableArray *toDelete = [NSMutableArray array];
    NSMutableArray *toReload = [NSMutableArray array];
    
    NSMutableSet *oldDataSet = [NSMutableSet setWithArray:oldData];
    NSMutableSet *dataSet = [NSMutableSet setWithArray:data];
    
    if (oldDataSet.count != oldData.count) {
        [self printDuplicates:oldData];
    }
    if (dataSet.count != data.count) {
        [self printDuplicates:data];
    }
    
    NSMutableOrderedSet *currentSet = [NSMutableOrderedSet orderedSetWithArray:oldData];
    for (NSUInteger index = 0; index < oldData.count; index++) {
        id object = oldData[index];
        if (![dataSet containsObject:object]) {
            [toDelete addObject:[NSIndexPath indexPathForItem:index inSection:0]];
            [currentSet removeObject:object];
        }
    }
    
    for (NSUInteger index = 0; index < data.count; index++) {
        id object = data[index];
        if (![oldDataSet containsObject:object]) {
            [toAdd addObject:[NSIndexPath indexPathForItem:index inSection:0]];
            [currentSet insertObject:object atIndex:index];
        } else {
            [toReload addObject:[NSIndexPath indexPathForItem:index inSection:0]];
        }
    }
    
    NSMutableArray *itemsToMove = [NSMutableArray array];
    for (NSUInteger index = 0; index < data.count; index++) {
        id object = data[index];
        NSUInteger oldDataIndex = [currentSet indexOfObject:object];
        if (index != oldDataIndex) {
            [itemsToMove addObject:@{ @"from" : [NSIndexPath indexPathForItem:[oldData indexOfObject:object] inSection:0],
                                      @"to" : [NSIndexPath indexPathForItem:index inSection:0] }];
        }
    }
    
    if (toDelete.count || toAdd.count || itemsToMove.count || toReload.count) {
        
        UIApplication *application = [UIApplication respondsToSelector:@selector(sharedApplication)] ? [UIApplication valueForKey:@"sharedApplication"] : nil;
        [application valueForKey:@"beginIgnoringInteractionEvents"];
        
        [self performBatchUpdates:^{
            if (updateObjects) {
                updateObjects();
            }
            
            [self deleteItemsAtIndexPaths:toDelete];
            [self insertItemsAtIndexPaths:toAdd];
            for (NSDictionary *dict in itemsToMove) {
                [self moveItemAtIndexPath:dict[@"from"] toIndexPath:dict[@"to"]];
            }
            
            for (NSIndexPath *indexPath in self.indexPathsForVisibleItems) {
                UICollectionViewCell *cell = [self cellForItemAtIndexPath:indexPath];
                
                if ([toAdd containsObject:indexPath]) {
                    [cell.superview sendSubviewToBack:cell];
                } else {
                    [cell.superview bringSubviewToFront:cell];
                }
            }
            
        } completion:^(BOOL finished) {
            [application valueForKey:@"endIgnoringInteractionEvents"];
            if (completion) {
                completion();
            }
        }];
        if (self.collectionViewLayout.collectionViewContentSize.height < self.bounds.size.height && data.count) {
            [UIView animateWithDuration:0.3 animations:^{
                [self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }];
        }
        
    } else {
        if (updateObjects) {
            updateObjects();
        }
        if (completion) {
            completion();
        }
    }
    
    return toReload;
}

@end
