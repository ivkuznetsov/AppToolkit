//
//  ReusableView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

open class ReusableView: UntouchableView {

    @IBInspectable public var nibName: String?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        var view: UIView?
        
        if let array = Bundle.main.loadNibNamed(nibName ?? String(describing: type(of: self)), owner: self, options: nil) {
            for object in array {
                if let object = object as? UIView {
                    view = object
                    break
                }
            }
        }
        if let view = view {
            view.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            insertSubview(view, at: 0)
            layoutMargins = .zero
        }
    }
}
