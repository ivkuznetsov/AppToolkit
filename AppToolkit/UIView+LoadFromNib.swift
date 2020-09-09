//
//  UIView+LoadFromNib.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

#if os(iOS)
import UIKit

public typealias View = UIView

#else
import AppKit

public typealias View = NSView

#endif

public extension View {
    
    @objc static func loadFromNib() -> Self {
        return loadFrom(nib: String(describing: self))
    }
    
    @objc static func loadFrom(nib: String) -> Self {
        return loadFrom(nib: nib, owner: nil)
    }
    
    @objc static func loadFrom(nib: String, owner: Any?) -> Self {
        return loadFrom(nib: nib, owner: owner, type: self)
    }
    
    static func loadFrom<T: View>(nib: String, owner: Any?, type: T.Type) -> T  {
        var bundle = Bundle.main
        if bundle.path(forResource: nib, ofType: "nib") == nil {
            bundle = Bundle(for: type)
        }
        
        var resultObject: T?
        var objects: [Any] = []
        
        #if os(iOS)
        objects = bundle.loadNibNamed(nib, owner: owner, options: nil) ?? []
        #else
        var array: NSArray? = nil
        Bundle.main.loadNibNamed(nib, owner: self, topLevelObjects: &array)
        objects = (array ?? []) as [Any]
        #endif
        
        for object in objects {
            if let object = object as? T {
                resultObject = object
                break
            }
        }
        return resultObject! // crash if didn't find
    }
}
