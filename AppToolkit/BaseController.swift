//
//  BaseController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATBaseController)
open class BaseController: UIViewController {
    
    private var viewLayouted: Bool = false
    
    public static var closeTitle: String?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open lazy var operationHelper: OperationHelper = {
        return OperationHelper(view: self.view)
    }()
    
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
            viewLayouted = true
        }
    }
}
