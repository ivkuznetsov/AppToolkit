//
//  RefreshControl.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

class RefreshControl: UIRefreshControl {
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if window != nil && isRefreshing, let scrollView = superview as? UIScrollView {
            let offset = scrollView.contentOffset
            UIView.performWithoutAnimation {
                endRefreshing()
            }
            beginRefreshing()
            scrollView.contentOffset = offset
        }
    }
}
