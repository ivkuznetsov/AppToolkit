//
//  ContainerTableCell.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATContainerTableCell)
open class ContainerTableCell: BaseTableViewCell {
    
    override open func prepareForReuse() {
        super.prepareForReuse()
        self.contentView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    func attach(view: UIView, useMargins: Bool) {
        backgroundColor = UIColor.clear
        selectionStyle = .none
        view.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        contentView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if useMargins {
            contentView.layoutMarginsGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        } else {
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
    }
    
    func attachWithoutConstraint(view: UIView) {
        backgroundColor = UIColor.clear
        selectionStyle = .none
        view.frame = CGRect(x: 0, y: 0, width: contentView.frame.size.width, height: contentView.frame.size.height)
        contentView.addSubview(view)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
