//
//  BaseRestorableViewController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 6/6/21.
//  Copyright © 2021 Ilya Kuznetsov. All rights reserved.
//

import UIKit

open class BaseRestorableViewController: BaseController, UIViewControllerRestoration {
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        restorationIdentifier = className()
        restorationClass = type(of: self)
    }
    
    required public override init() {
        super.init()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        return self.init()
    }
    
    open override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        children.forEach { vc in
            if vc.restorationIdentifier != nil {
                vc.encode(with: coder)
            }
        }
    }
    
    open override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        children.forEach { vc in
            if vc.restorationIdentifier != nil {
                vc.decodeRestorableState(with: coder)
            }
        }
    }
}
