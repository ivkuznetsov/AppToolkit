//
//  UITableView+Reloading.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

public extension UITableView {
    
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
    
    func reload(oldData: [AnyHashable], newData: [AnyHashable], deferred: (()->())?, updateObjects: (()->())?, addAnimation: UITableView.RowAnimation) {
        
        var toAdd: [IndexPath] = []
        var toDelete: [IndexPath] = []
        
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
                toDelete.append(IndexPath(row: index, section: 0))
                currentSet.remove(object)
            }
        }
        for (index, object) in newData.enumerated() {
            if !oldDataSet.contains(object) {
                toAdd.append(IndexPath(row: index, section: 0))
                currentSet.insert(object, at: index)
            }
        }
        
        var itemsToMove: [(from: IndexPath, to: IndexPath)] = []
        for (index, object) in newData.enumerated() {
            let oldDataIndex = currentSet.index(of: object)
            if index != oldDataIndex {
                itemsToMove.append((from: IndexPath(row: oldData.firstIndex(of: object)!, section: 0), to: IndexPath(row: index, section: 0)))
            }
        }
        
        self.beginUpdates()
        
        updateObjects?()
        
        if !toDelete.isEmpty {
            self.deleteRows(at: toDelete, with: .fade)
        }
        if !toAdd.isEmpty {
            self.insertRows(at: toAdd, with: addAnimation)
        }
        if !itemsToMove.isEmpty {
            for couple in itemsToMove {
                self.moveRow(at: couple.from, to: couple.to)
            }
        }
        
        deferred?()
        
        self.endUpdates()
    }
}
