//
//  FadeButton.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATFadeButton)
open class FadeButton: UIButton {
    
    @IBOutlet open weak var additionalView: UIView?
    @IBInspectable open var animatedHiglight: Bool = true
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                alpha = 0.5
            } else if isEnabled {
                alpha = 1.0
                
                if (animatedHiglight) {
                    let tranition = CATransition()
                    tranition.duration = 0.15
                    layer.add(tranition, forKey: nil)
                    additionalView?.layer.add(tranition, forKey: nil)
                }
            }
        }
    }
    
    open override var isEnabled: Bool {
        didSet {
            if isEnabled {
                alpha = isHighlighted ? 0.5 : 1.0
            } else {
                alpha = 0.5
            }
        }
    }
    
    open override var alpha: CGFloat {
        didSet {
            additionalView?.alpha = alpha
        }
    }
    
    open override var isHidden: Bool {
        didSet {
            additionalView?.isHidden = isHidden
        }
    }
}
