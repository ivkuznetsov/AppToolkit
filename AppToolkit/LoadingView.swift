//
//  LoadingView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objcMembers
@objc(ATLoadingView)
open class LoadingView : UIView {
    
    @IBOutlet open var indicator: UIActivityIndicatorView!
    @IBOutlet open var progressIndicator: CircularProgressView?
    
    open var opaqueStyle: Bool = false {
        didSet {
            backgroundColor = backgroundColor?.withAlphaComponent(opaqueStyle ? 1.0 : 0.6)
        }
    }
    
    open func performLazyLoading(showBackground: Bool) {
        let color = backgroundColor
        indicator.isHidden = true
        
        if !showBackground {
            backgroundColor = .clear
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.backgroundColor = color
            self?.addFadeTransition()
            if let wSelf = self, wSelf.progressIndicator?.isHidden != false {
                wSelf.indicator.isHidden = false
            }
        }
    }
    
    open var progress: CGFloat = 0 {
        didSet {
            indicator.isHidden = true
            progressIndicator?.isHidden = false
            progressIndicator?.progress = progress
        }
    }
    
    open class func present(in view: UIView, animated: Bool) -> Self {
        let loadingView = loadFromNib()
        
        loadingView.frame = view.bounds
        loadingView.progressIndicator?.isHidden = true
        loadingView.opaqueStyle = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(loadingView)
        view.leftAnchor.constraint(equalTo: loadingView.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: loadingView.rightAnchor).isActive = true
        view.topAnchor.constraint(equalTo: loadingView.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor).isActive = true
        
        if animated {
            loadingView.alpha = 0
            UIView.animate(withDuration: 0.2, animations: {
                loadingView.alpha = 1
            })
        }
        return loadingView
    }
    
    open func hide(_ animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
            }, completion: { (_) in
                self.removeFromSuperview()
            })
        } else {
            removeFromSuperview()
        }
    }
}
