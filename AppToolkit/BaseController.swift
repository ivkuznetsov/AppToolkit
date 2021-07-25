//
//  BaseController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATBaseController)
open class BaseController: UIViewController, UIViewControllerRestoration {
    
    private var viewLayouted: Bool = false
    
    public static var closeTitle: String?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    open func commonInit() {
        if self is Restorable {
            if restorationIdentifier == nil {
                restorationIdentifier = className()
            }
            restorationClass = type(of: self)
        }
    }
    
    open lazy var operationHelper: OperationHelper = {
        return OperationHelper(view: self.view)
    }()
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self is Restorable && navigationController?.restorationIdentifier == nil {
            navigationController?.restorationIdentifier = "Navigation" + className()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        if let nc = self.navigationController,
            nc.presentingViewController != nil,
            let index = nc.viewControllers.firstIndex(of: self),
            (index == 0 || nc.viewControllers[index - 1].navigationItem.rightBarButtonItem?.action == #selector(closeAction) ) {
            
            createCloseButton()
        }
    }
    
    open func createCloseButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: type(of: self).closeTitle ?? "Close", style: .plain, target: self, action: #selector(closeAction))
    }
    
    open func previousViewController() -> UIViewController? {
        if let array = self.navigationController?.viewControllers, let index = array.firstIndex(of: self), index != 0 {
            return array[index - 1]
        }
        return nil
    }
    
    @IBAction open func closeAction() {
        if let nc = self.navigationController {
            if nc.presentingViewController != nil {
                nc.dismiss(animated: true, completion: nil)
            } else if let parentVC = self.parent, let nc = parentVC.navigationController, nc.presentingViewController != nil {
                nc.dismiss(animated: true, completion: nil)
            } else {
                nc.popViewController(animated: true)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    open func reloadView(_ animated: Bool) {
        
    }
    
    open func performOnFirstLayout() {
        
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !viewLayouted {
            performOnFirstLayout()
            restoreScrollViews()
            viewLayouted = true
        }
    }
    
    open class func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        if let wSelf = self as? (UIViewController & Restorable).Type {
            return wSelf.init()
        }
        return nil
    }
    
    private var scrollViewsToRestore: [(UIScrollView, CGPoint)] = []
    
    private func restoreScrollViews() {
        scrollViewsToRestore.forEach { $0.contentOffset = $1 }
        scrollViewsToRestore.removeAll()
    }
    
    open func process(_ scrollView: UIScrollView, key: String, operation: RestorableOperation) {
          if operation.operationType == .store {
            operation.coder.encode(scrollView.contentOffset, forKey: key)
        } else {
            if let point = operation.coder.decodeObject(forKey: key) as? CGPoint {
                scrollViewsToRestore.append((scrollView, point))
            }
        }
    }
    
    open override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        if let restorable = self as? Restorable {
            restorable.processKeypaths(RestorableOperation(operationType: .store, coder: coder))
            
            children.forEach { vc in
                if let restorationId = vc.restorationIdentifier {
                    if let tabVC = vc as? UITabBarController {
                        tabVC.encode(with: coder)
                    } else {
                        let archiver = NSKeyedArchiver()
                        vc.encodeRestorableState(with: archiver)
                        coder.encode(archiver.encodedData, forKey: restorationId)
                    }
                }
            }
        }
    }
    
    open override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        if let restorable = self as? Restorable {
            restorable.processKeypaths(RestorableOperation(operationType: .restore, coder: coder))
            
            children.forEach { vc in
                if let restorationId = vc.restorationIdentifier {
                    if let tabVC = vc as? UITabBarController {
                        tabVC.decodeRestorableState(with: coder)
                    } else if let data = coder.decodeObject(forKey: restorationId) as? Data {
                        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
                        vc.decodeRestorableState(with: unarchiver)
                    }
                }
            }
        }
    }
}
