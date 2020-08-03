//
//  ReusableView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

#if os(macOS)

import AppKit

open class ReusableView: NSView {

    @IBInspectable public var nibName: String?
    private var nibLoaded = false
    
    open override func awakeFromNib() {
        if nibLoaded {
            return
        }
        super.awakeFromNib()
        
        var view: NSView?
        
        var array: NSArray? = nil
        nibLoaded = true
        Bundle.main.loadNibNamed(nibName ?? String(describing: type(of: self)), owner: self, topLevelObjects: &array)
        
        if let array = array {
            for object in array {
                if let object = object as? NSView {
                    view = object
                    break
                }
            }
        }
        if let view = view {
            view.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }
}

#else

import UIKit

open class ReusableView: UntouchableView {

    @IBInspectable public var nibName: String?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        var view: UIView?
        
        if let array = Bundle.main.loadNibNamed(nibName ?? String(describing: type(of: self)), owner: self, options: nil) {
            for object in array {
                if let object = object as? UIView {
                    view = object
                    break
                }
            }
        }
        if let view = view {
            view.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            insertSubview(view, at: 0)
            layoutMargins = .zero
        }
    }
}

#endif
