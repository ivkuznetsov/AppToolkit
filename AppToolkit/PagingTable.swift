//
//  PagingTable.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 11/26/17.
//  Copyright © 2017 Ilya Kuznetsov. All rights reserved.
//

import Foundation

@objc(ATPagingTable)
open class PagingTable: Table {
    
    @objc open private(set) var loader: PagingLoader!
    private weak var pagingDelegate: PagingLoaderDelegate?
    
    override func setup() {
        super.setup()
        
        let loaderType = pagingDelegate?.pagingLoader?() ?? PagingLoader.self
        
        self.loader = loaderType.init(scrollView: table,
                                 delegate: pagingDelegate!,
                                 addRefreshControl: { [unowned self] (control) in
                                    
                                    if #available(iOS 10.0, *) {
                                        self.table.refreshControl = control
                                    } else {
                                        self.table.insertSubview(control, at: 0)
                                    }
                                    
            }, scrollOnRefreshing: { [weak self] (control) in
                
                self?.table.contentOffset = CGPoint(x: 0, y: -control.bounds.size.height)
                
            }, setFooterVisible: { [weak self] (visible, footerView) in
                
                if let wSelf = self {
                    let offset = wSelf.table.contentOffset
                    wSelf.table.tableFooterView = visible ? footerView : UIView()
                    wSelf.table.contentOffset = offset
                }
        })
    }
    
    @objc public init(table: UITableView, pagingDelegate: PagingLoaderDelegate & TableDelegate) {
        self.pagingDelegate = pagingDelegate
        super.init(table: table, delegate: pagingDelegate)
    }
    
    @objc public convenience init(view: UIView, pagingDelegate: PagingLoaderDelegate & TableDelegate) {
        self.init(view: view, style: .plain, pagingDelegate: pagingDelegate)
    }
    
    @objc public init(view: UIView, style: UITableView.Style, pagingDelegate: PagingLoaderDelegate & TableDelegate) {
        self.pagingDelegate = pagingDelegate
        super.init(view: view, style: style, delegate: pagingDelegate)
    }
    
    @objc public convenience init(customAdd: (UITableView)->(), pagingDelegate: PagingLoaderDelegate & TableDelegate) {
        self.init(customAdd: customAdd, style: .plain, pagingDelegate: pagingDelegate)
    }
    
    @objc public init(customAdd: (UITableView)->(), style: UITableView.Style, pagingDelegate: PagingLoaderDelegate & TableDelegate) {
        self.pagingDelegate = pagingDelegate
        super.init(customAdd: customAdd, style: style, delegate: pagingDelegate)
    }
}

extension PagingTable {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        loader.endDecelerating()
        delegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loader.endDecelerating()
        }
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
}
