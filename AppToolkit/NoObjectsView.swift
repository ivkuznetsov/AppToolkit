//
//  NoObjectsView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

open class NoObjectsView: UIView {
    
    @IBOutlet open var titleLabel: UILabel!
    @IBOutlet open var detailsLabel: UILabel!
    @IBOutlet open var actionButton: BorderedButton?
    @IBOutlet open var centerConstraint: NSLayoutConstraint?
    
    open var actionClosure: (()->())? {
        didSet {
            actionButton?.isHidden = actionClosure == nil
        }
    }
    
    @IBAction private func action(sender: UIButton) {
        actionClosure?()
    }
}
