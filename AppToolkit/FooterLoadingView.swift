//
//  FooterLoadingView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATFooterState)
public enum FooterState: Int {
    case undefined
    case stop
    case loading
    case failed
}

@objc(ATFooterLoadingView)
open class FooterLoadingView: UIView {
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        state = .stop
    }
    
    @objc open var state: FooterState = .undefined {
        didSet {
            if state != oldValue {
                switch state {
                case .stop:
                    indicatorView.stopAnimating()
                    retryButton.isHidden = true
                case .loading:
                    indicatorView.startAnimating()
                    retryButton.isHidden = true
                case .failed:
                    indicatorView.stopAnimating()
                    retryButton.isHidden = false
                default: break
                }
            }
        }
    }
    @objc open var retry: (()->())?
    
    @IBOutlet open var indicatorView: UIActivityIndicatorView!
    @IBOutlet open var retryButton: UIButton!
    
    @IBAction private func retryAction(_ sender: UIButton) {
        retry?()
    }
}
