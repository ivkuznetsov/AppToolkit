//
//  UIView+LoadFromNib.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

public extension UIView {
    
    @objc static func loadFromNib() -> Self {
        return loadFrom(nib: String(describing: self))
    }
    
    @objc static func loadFrom(nib: String) -> Self {
        return loadFrom(nib: nib, owner: nil)
    }
    
    @objc static func loadFrom(nib: String, owner: Any?) -> Self {
        return loadFrom(nib: nib, owner: owner, type: self)
    }
    
    static func loadFrom<T: UIView>(nib: String, owner: Any?, type: T.Type) -> T  {
        var bundle = Bundle.main
        if bundle.path(forResource: nib, ofType: "nib") == nil {
            bundle = Bundle(for: type)
        }
        
        var resultObject: T?
        if let objects = bundle.loadNibNamed(nib, owner: owner, options: nil) {
            for object in objects {
                if let object = object as? T {
                    resultObject = object
                    break
                }
            }
        }
        return resultObject! // crash if didn't find
    }
}
