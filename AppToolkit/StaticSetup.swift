//
//  LazySetup.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/5/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

@objc(ATStaticSetup)
public class StaticSetup: NSObject {
    
    private static var setupClosures: [String:[(StaticSetupObject)->()]] = [:]
    
    public static func setup<T: StaticSetupObject>(_ type: T.Type, _ closure: @escaping (T)->()) {
        var array = setupClosures[String(describing: type)] ?? []
        array.append({ (object) in
            closure(object as! T)
        })
        setupClosures[String(describing: type)] = array
    }
    
    fileprivate static func performSetup(object: StaticSetupObject) {
        if let closures = setupClosures[String(describing: type(of: object))] {
            closures.forEach({ (closure) in
                closure(object)
            })
        }
    }
}

@objc(ATStaticSetupObject)
open class StaticSetupObject: NSObject {
    
    public override init() {
        super.init()
        StaticSetup.performSetup(object: self)
    }
}

@available(swift, obsoleted: 1.0)
public extension StaticSetup {
    
    @objc static func setupFor(_ type: AnyClass, block: @escaping (AnyObject)->()) {
        setup(type as! StaticSetupObject.Type, block)
    }
}
