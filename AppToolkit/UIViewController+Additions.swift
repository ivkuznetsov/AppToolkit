//
//  UIViewController+Additions.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 4/7/21.
//  Copyright © 2021 Ilya Kuznetsov. All rights reserved.
//

import Foundation

public extension UIViewController {
    
    static var topViewController: UIViewController? {
        var topVC: UIViewController?
        
        if let shared = UIApplication.value(forKey: "sharedApplication") as? UIApplication {
            topVC = shared.delegate?.window??.rootViewController
        }
        
        while topVC?.presentedViewController != nil {
            topVC = topVC?.presentedViewController
        }
        
        return topVC
    }
}
