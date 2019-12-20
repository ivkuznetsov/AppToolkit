//
//  Observable.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public protocol Observable: class {
    
    static func notificationName() -> String
    
    func observe(_ observer: AnyObject, closure: @escaping (Notification?)->())
    
    static func observe(_ observer: AnyObject, closure: @escaping (Notification?)->())
    
    // removing observer is not necessary, it will be removed after object gets deallocated
    static func cancelObserving(_ observer: AnyObject)
    
    static func post(_ notification: Notification?)
    func post(_ notification: Notification?)
}

public extension Observable {
    
    static func notificationName() -> String {
        return String(describing: self)
    }
    
    func observe(_ observer: AnyObject, closure: @escaping (Notification?)->()) {
        type(of: self).observe(observer) { [unowned self] (notification) in
            if notification == nil || notification!.object == nil || notification!.object! === self {
                closure(notification)
            }
        }
    }
    
    static func observe(_ observer: AnyObject, closure: @escaping (Notification?)->()) {
        NotificationManager.shared.add(observer: observer, closure: closure, names: [notificationName()])
    }
    
    static func cancelObserving(_ observer: AnyObject) {
        NotificationManager.shared.remove(observer: observer, names: [notificationName()])
    }
    
    static func post(_ notification: Notification?) {
        NotificationManager.shared.postNotification(names: [notificationName()], notification: notification)
    }
    
    func post(_ notification: Notification?) {
        let notification = notification ?? Notification()
        notification.object = self
        type(of: self).post(notification)
    }
}
