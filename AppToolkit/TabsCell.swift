//
//  TabsCell.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc open class TabsCell: UIView {
    
    private var fillWidth = false
    public private(set) var tabsView: TabsView! {
        didSet {
            tabsView.translatesAutoresizingMaskIntoConstraints = false
            self.insertSubview(tabsView, at: 0)
            
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[tabsView]|", options: [], metrics: nil, views: ["tabsView":tabsView!])
            constraints.forEach {
                $0.priority = UILayoutPriority(900)
            }
            self.addConstraints(constraints)
            
            if fillWidth {
                let constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[tabsView]|", options: [], metrics: nil, views: ["tabsView":tabsView!])
                constraints.forEach {
                    $0.priority = UILayoutPriority(900)
                }
                self.addConstraints(constraints)
            } else {
                self.addConstraint(NSLayoutConstraint(item: tabsView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
            }
        }
    }
    
    open class func make(titles: [String], fillWidth: Bool, action: @escaping (Int)->()) -> Self {
        let view = self.loadFromNib()
        view.fillWidth = fillWidth
        view.tabsView = TabsView(titles: titles, style: .dark, didSelect: { (button, animated) in
            action(button.tag)
        })
        return view
    }
    
    open class func make(titles: [String], action: @escaping (Int)->()) -> Self {
        return make(titles: titles, fillWidth: false, action: action)
    }
}
