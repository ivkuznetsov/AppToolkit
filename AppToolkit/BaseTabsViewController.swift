//
//  BaseTabsViewController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATBaseTabsViewController)
open class BaseTabsViewController: BaseRestorableViewController {
    
    open var viewControllers: [UIViewController]!
    open private(set) var currentViewController: UIViewController?
    
    @IBOutlet open var containerView: UIView!
    @IBOutlet open var tabsContainerView: UIView? // navigationItem.titleView if nil
    private var tabsWidthConstraint: NSLayoutConstraint?
    
    open var tabsView: TabsView!
    
    public required init() {
        super.init()
    }
    
    public init(viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        super.init()
    }
    
    public init?(coder aDecoder: NSCoder, viewControllers:[UIViewController]) {
        self.viewControllers = viewControllers
        super.init(coder: aDecoder)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        tabsView = TabsView(titles: viewControllers.map{ $0.title! }, style: .dark, didSelect: { [unowned self] (button, animated) in
            _ = self.selectController(at: button.tag, animated: animated)
        })
        
        if tabsContainerView != nil {
            attachTabsViewToContainer()
        } else {
            navigationItem.titleView = tabsView
            
            let insets = navigationController!.navigationBar.layoutMargins
            let rect = navigationController!.navigationBar.frame
            
            let width = screenWidth() - insets.right - insets.left
            
            tabsView.translatesAutoresizingMaskIntoConstraints = false
            tabsView.frame = CGRect(x: insets.left, y: 0, width: width, height: rect.size.height)
            
            let constraint = NSLayoutConstraint(item: tabsView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 44)
            constraint.priority = UILayoutPriority(900)
            
            tabsView.addConstraint(constraint)
        }
        _ = selectController(at: 0, animated: false)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(gr:)))
        swipeLeft.direction = .left
        swipeLeft.delegate = self
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(gr:)))
        swipeRight.direction = .right
        swipeRight.delegate = self
        self.view.addGestureRecognizer(swipeRight)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tabsFillWidth() && tabsContainerView == nil {
            tabsWidthConstraint = tabsView.widthAnchor.constraint(equalTo: navigationController!.navigationBar.widthAnchor, multiplier: 1)
            tabsView.wasAddedToSuperview = { [weak self] in
                self?.tabsWidthConstraint?.isActive = true
            }
            if tabsView.superview != nil {
                tabsWidthConstraint?.isActive = true
            }
        }
    }
    
    @objc open func swipeAction(gr: UISwipeGestureRecognizer) {
        if gr.direction == .left {
            if let index = tabsView.selectNext(animated: true) {
                _ = selectController(at: index, animated: true)
            }
        } else if gr.direction == .right {
            if let index = tabsView.selectPrevious(animated: true) {
                _ = selectController(at: index, animated: true)
            }
        }
    }
    
    open func attachTabsViewToContainer() {
        if let tabsContainer = tabsContainerView {
            tabsView.removeFromSuperview()
            
            tabsView.translatesAutoresizingMaskIntoConstraints = false
            tabsContainer.addSubview(tabsView)
            
            tabsContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[tabsView]|", options: [], metrics: nil, views: ["tabsView":tabsView!]))
            
            if tabsFillWidth() {
                tabsContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tabsView]|", options: [], metrics: nil, views: ["tabsView":tabsView!]))
            } else {
                tabsContainer.addConstraint(NSLayoutConstraint(item: tabsView!, attribute: .centerX, relatedBy: .equal, toItem: tabsContainerView, attribute: .centerX, multiplier: 1, constant: 0))
            }
        }
    }
    
    open func selectController(at index: Int) -> UIViewController {
        tabsView.selectTab(index: index, animated: false)
        return selectController(at: index, animated: false)
    }
    
    open func selectController(at index: Int, animated: Bool) -> UIViewController {
        if tabsView.hiddenTabs.contains(index) {
            return currentViewController!
        }
        
        let vc = viewControllers[index]
        if vc == currentViewController {
            return vc
        }
        if let currentViewController = currentViewController, animated {
            if viewControllers.firstIndex(of: currentViewController)! < viewControllers.firstIndex(of: vc)! {
                containerView.addPushTransition()
            } else {
                containerView.addPopTransition()
            }
        }
        
        currentViewController?.removeFromParent()
        currentViewController?.view.removeFromSuperview()
        currentViewController = vc
        self.addChild(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        return currentViewController!
    }
    
    open func screenWidth() -> CGFloat {
        return min(self.view.width, self.view.height)
    }
    
    open func tabsFillWidth() -> Bool {
        return false
    }
}

extension BaseTabsViewController: UIGestureRecognizerDelegate { }
