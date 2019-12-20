//
//  ContainerCollectionCell.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

open class ContainerCollectionCell: UICollectionViewCell {
    
    open var untouchable = false
    open var attachedView: UIView? {
        return contentView.subviews.last
    }
    
    func attach(view: UIView) {
        if view == contentView.subviews.last {
            return
        }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        contentView.frame = bounds
        view.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(view)
        
        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        let constraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        constraint.priority = UILayoutPriority(900)
        constraint.isActive = true
    }
    
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let view = super.hitTest(point, with: event) {
            return (untouchable && (view == self || view == contentView)) ? nil : view
        }
        return nil
    }
}
