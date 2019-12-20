//
//  AlerBarView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

open class AlertBarView: UIView {
    
    @IBOutlet private var textLabel: UILabel!
    open var dismissTime: TimeInterval = 5
    
    open class func present(in view: UIView, message: String) -> Self {
        let barView = loadFromNib()
        barView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(barView)
        view.leftAnchor.constraint(equalTo: barView.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: barView.rightAnchor).isActive = true
        
        let next = view.next
        if let next = next as? UIViewController {
            next.view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: barView.topAnchor).isActive = true
        } else if next as? UIView != nil {
            view.topAnchor.constraint(equalTo: barView.topAnchor).isActive = true
        }
        
        barView.textLabel.text = message
        barView.alpha = 0
        barView.textLabel.superview?.transform = CGAffineTransform(translationX: 0, y: -barView.bounds.size.height)
        UIView.animate(withDuration: 0.25) {
            barView.textLabel.superview?.transform = .identity
            barView.alpha = 1
        }
        
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + barView.dismissTime) {
                barView.hide()
            }
        }
        return barView
    }
    
    open func message() -> String {
        return textLabel.text!
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.superview?.layer.cornerRadius = 6.0
    }
    
    open func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0.0
        }) { (_) in
            self.removeFromSuperview()
        }
    }
}
