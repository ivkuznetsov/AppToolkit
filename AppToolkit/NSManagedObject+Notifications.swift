//
//  NSManagedObject+Notifications.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObject {

    @objc static func add(observer: AnyObject, closure: @escaping (Notification?)->()) {
        self.add(observer: observer, closure: closure, classes: [self])
    }
    
    @objc static func remove(observer: AnyObject) {
        self.remove(observer: observer, classes: [self])
    }
    
    @objc static func add(observer: AnyObject, closure: @escaping (Notification?)->(), classes: [NSManagedObject.Type]) {
        NotificationManager.shared.add(observer: observer, closure: closure, names: classNamesFor(classes: classes))
    }
    
    @objc static func remove(observer: AnyObject, classes: [NSManagedObject.Type]) {
        NotificationManager.shared.remove(observer: observer, names: classNamesFor(classes: classes))
    }
    
    @objc static func postUpdatesFor(classes: [NSManagedObject.Type], notification: Notification?) {
        NotificationManager.shared.postNotification(names: classNamesFor(classes: classes), notification: notification)
    }
    
    @objc private static func classNamesFor(classes: [NSManagedObject.Type]) -> [String] {
        return classes.map { String(describing: $0) }
    }
}
