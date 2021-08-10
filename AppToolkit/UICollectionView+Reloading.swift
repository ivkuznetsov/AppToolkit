//
//  UICollectionView+Reloading.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 8/10/21.
//  Copyright © 2021 Ilya Kuznetsov. All rights reserved.
//

import UIKit

public extension UICollectionView {
    
    private func printDuplicates(_ array: [AnyHashable]) {
        var allSet = Set<AnyHashable>()
        
        for object in array {
            if allSet.contains(object) {
                print("found duplicated object %@", object.description)
            } else {
                allSet.insert(object)
            }
        }
    }
    
    func reload(animated: Bool, oldData: [AnyHashable], newData: [AnyHashable], completion: (()->())?, updateObjects: (()->())?) -> [IndexPath] {
        
        var applicationPresented = true
        var application: UIApplication?
        
        if Bundle.main.bundleURL.pathExtension != "appex" {
            application = (UIApplication.value(forKey: "sharedApplication") as! UIApplication)
            applicationPresented = application!.applicationState == .active
        }
        
        if !animated || oldData.isEmpty || window == nil || !applicationPresented {
            updateObjects?()
            reloadData()
            layoutIfNeeded()
            completion?()
            return []
        }
        
        var toAdd: [IndexPath] = []
        var toDelete: [IndexPath] = []
        var toReload: [IndexPath] = []
        
        let oldDataSet = Set(oldData)
        let newDataSet = Set(newData)
        
        if oldDataSet.count != oldData.count {
            printDuplicates(oldData)
        }
        if newDataSet.count != newData.count {
            printDuplicates(newData)
        }
        
        let currentSet = NSMutableOrderedSet(array: oldData)
        for (index, object) in oldData.enumerated() {
            if !newDataSet.contains(object) {
                toDelete.append(IndexPath(item: index, section: 0))
                currentSet.remove(object)
            }
        }
        for (index, object) in newData.enumerated() {
            if !oldDataSet.contains(object) {
                toAdd.append(IndexPath(item: index, section: 0))
                currentSet.insert(object, at: index)
            } else {
                toReload.append(IndexPath(item: index, section: 0))
            }
        }
        
        var itemsToMove: [(from: IndexPath, to: IndexPath)] = []
        for (index, object) in newData.enumerated() {
            let oldDataIndex = currentSet.index(of: object)
            if index != oldDataIndex {
                itemsToMove.append((from: IndexPath(item: oldData.firstIndex(of: object)!, section: 0), to: IndexPath(item: index, section: 0)))
            }
        }
        
        if toDelete.count > 0 || toAdd.count > 0 || itemsToMove.count > 0 || toReload.count > 0 {
            
            application?.value(forKey: "beginIgnoringInteractionEvents")
            
            performBatchUpdates {
                updateObjects?()
                
                deleteItems(at: toDelete)
                insertItems(at: toAdd)
                
                itemsToMove.forEach { moveItem(at: $0, to: $1) }
                
                let visibleItems = indexPathsForVisibleItems
                
                if visibleItems.count > 0 {
                    let toAddSet = Set(toAdd)
                    
                    visibleItems.forEach {
                        if let cell = cellForItem(at: $0) {
                            if toAddSet.contains($0) {
                                cell.superview?.sendSubviewToBack(cell)
                            } else {
                                cell.superview?.bringSubviewToFront(cell)
                            }
                        }
                    }
                }
                
            } completion: { _ in
                application?.value(forKey: "endIgnoringInteractionEvents")
                completion?()
            }

            if collectionViewLayout.collectionViewContentSize.height < bounds.size.height && newData.count > 0 {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
                }
            }
        } else {
            updateObjects?()
            completion?()
        }
        return toReload
    }
}
