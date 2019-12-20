//
//  FailedView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATFailedView)
open class FailedView: UIView {
    
    @IBOutlet open var textLabel: UILabel!
    @IBOutlet open var retryButton: BorderedButton!
    
    private var retry: (()->())? {
        didSet {
            if retryButton != nil {
                retryButton.isHidden = retry == nil
            }
        }
    }
    
    @objc open class func present(in view: UIView, text: String, retry: (()->())?) -> Self {
        let faliedView = self.loadFromNib()
        faliedView.frame = view.bounds
        faliedView.textLabel.text = text
        faliedView.retry = retry
        view.addSubview(faliedView)
        
        faliedView.translatesAutoresizingMaskIntoConstraints = false
        view.leftAnchor.constraint(equalTo: faliedView.leftAnchor).isActive = true
        view.topAnchor.constraint(equalTo: faliedView.topAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: faliedView.rightAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: faliedView.bottomAnchor).isActive = true
        
        faliedView.configure()
        
        return faliedView
    }
    
    open func configure() { }
    
    @IBAction private func retryAction(_ sender: UIButton) {
        retry?()
    }
}
