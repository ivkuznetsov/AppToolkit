//
//  Table.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc public enum AResult: Int {
    case deselect
    case select
    case unsupported
}

@objc public protocol TableDelegate: UITableViewDelegate {
    
    //fade by default
    @objc optional func animationForAdding(table: Table) -> UITableView.RowAnimation
    
    //by default it becomes visible when objects array is empty
    @objc optional func shouldShowNoData(objects: [AnyHashable], table: Table) -> Bool
    
    //BOOL returns is we need to deselect cell
    @objc optional func action(object: Any, table: Table) -> AResult
    
    @objc optional func createCell(object: Any, table: Table) -> Any?
    
    @objc optional func cellHeight(object: Any, def: CGFloat, table: Table) -> CGFloat
    
    @objc optional func cellEstimatedHeight(object: Any, def: CGFloat, table: Table) -> CGFloat
}

@objc public protocol TEditable: class {
    
    func cellEditor(object: Any, table: Table) -> Any?
}

public struct TEditor {
    
    fileprivate var editingStyle: UITableViewCell.EditingStyle = .delete
    fileprivate var action: (()->())?
    fileprivate var actions: (()->([UIContextualAction]))?
    
    public init(delete: @escaping ()->()) {
        editingStyle = .delete
        action = delete
    }
    
    public init(insert: @escaping ()->()) {
        editingStyle = .insert
        action = insert
    }
    
    public init(actions: @escaping ()->([UIContextualAction])) {
        self.actions = actions
    }
}

public struct TCell {
    
    public var cellType: UITableViewCell.Type
    public var cellFill: ((UITableViewCell)->())?
    
    public init<T: UITableViewCell>(_ type: T.Type, _ fill: ((T)->())?) {
        self.cellType = type
        if let fill = fill {
            self.cellFill = { (cell) in
                fill(cell as! T)
            }
        }
    }
}

fileprivate extension TableDelegate {
    func editable() -> TEditable? {
        return self as? TEditable
    }
}

@objc(ATTable)
open class Table: StaticSetupObject {
    
    @objc open var useMarginsForContainerCells: Bool = false
    private var deferredUpdate: Bool = false
    @objc open var visible: Bool = true { // defer reload when view is not visible
        didSet {
            if visible && (visible != oldValue) && deferredUpdate {
                set(objects: objects, animated: false)
            }
        }
    }
    //use constraints for attacing UIView to TableContainerCell
    @objc var attachViewsByConstraints: Bool = true
    
    public static var defaultDelegate: TableDelegate?
    @objc open private(set) var table: UITableView!
    @objc open private(set) var objects: [AnyHashable] = []
    
    //for edit/done button
    @objc open weak var navigationItem: UINavigationItem?
    @objc open var processEditing: ((@escaping ()->())->())?
    
    private lazy var editButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editAction))
    }()
    private lazy var doneButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editAction))
    }()
    
    //empty state
    @objc open var noObjectsViewType: NoObjectsView.Type! {
        didSet {
            noObjectsView = noObjectsViewType.loadFromNib()
        }
    }
    @objc open private(set) var noObjectsView: NoObjectsView!
    
    weak var delegate: TableDelegate?
    fileprivate var estimatedHeights: [NSValue:CGFloat] = [:]
    
    @objc public init(table: UITableView, delegate: TableDelegate) {
        self.table = table
        self.delegate = delegate
        super.init()
        setup()
    }
    
    //these methods create UITableView, by default tableView fills view, if you need something else use addBlock
    @objc public convenience init(view: UIView, delegate: TableDelegate) {
        self.init(view: view, style: .plain, delegate: delegate)
    }
    
    @objc public init(view: UIView, style: UITableView.Style, delegate: TableDelegate) {
        self.delegate = delegate
        super.init()
        self.createTable(style: style)
        table.frame = view.bounds
        view.addSubview(table)
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[table]|", options: [], metrics: nil, views: ["table" : table!]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[table]|", options: [], metrics: nil, views: ["table" : table!]))
        setup()
    }
    
    @objc public convenience init(customAdd: (UITableView)->(), delegate: TableDelegate) {
        self.init(customAdd: customAdd, style: .plain, delegate: delegate)
    }
    
    @objc public init(customAdd: (UITableView)->(), style: UITableView.Style, delegate: TableDelegate) {
        self.delegate = delegate
        super.init()
        self.createTable(style: style)
        customAdd(table)
        setup()
    }
    
    @objc open func set(objects: [Any], animated: Bool) {
        let oldObjects = self.objects
        let resultObjects = objects.map { (object) -> AnyHashable in
            if let object = object as? NSObject {
                return object
            }
            return object as! AnyHashable
        }
        
        if !visible && self.objects.count == resultObjects.count {
            self.objects = resultObjects
            deferredUpdate = true
            return
        }
        
        if delegate == nil {
            return
        }
        
        // remove missed estimated heights
        var set = Set(estimatedHeights.keys)
        objects.forEach { set.remove(estimatedHeightKeyFor(object: $0)) }
        set.forEach { estimatedHeights[$0] = nil }
        
        if !deferredUpdate && (animated && oldObjects.count > 0) {
            table.reload(oldData: oldObjects, newData: resultObjects, deferred: { [weak self] in
                
                self?.reloadVisibleCells()
            }, updateObjects: { [weak self] in
                
                self?.objects = resultObjects
                
            }, addAnimation: self.delegate?.animationForAdding?(table: self) ??
                    (type(of: self).defaultDelegate?.animationForAdding?(table: self) ?? .fade))
            
        } else {
            self.objects = resultObjects
            table.reloadData()
            deferredUpdate = false
        }
        
        if delegate?.shouldShowNoData?(objects: resultObjects, table: self) ??
            (type(of: self).defaultDelegate?.shouldShowNoData?(objects: resultObjects, table: self) ?? (objects.count == 0)) {
            
            noObjectsView.frame = CGRect(x: 0, y: 0, width: table.frame.size.width, height: table.frame.size.height)
            table.addSubview(noObjectsView)
        } else {
            noObjectsView.removeFromSuperview()
        }
        reloadEditButton(animated: animated)
    }
    
    @objc open func scrollTo(object: Any, animated: Bool) {
        // swift leaks if reference object in "Any" cast to AnyHashable
        if let object = object as? NSObject, let index = objects.firstIndex(of: object) {
            table.scrollToRow(at: IndexPath(row: index, section:0), at: .none, animated: animated)
        } else if let object = object as? AnyHashable, let index = objects.firstIndex(of: object) {
            table.scrollToRow(at: IndexPath(row: index, section:0), at: .none, animated: animated)
        }
    }
    
    open func reloadVisibleCells() {
        self.table.visibleCells.forEach {
            var resIndex: Int?
            
            if let cell = $0 as? TCellObjectHolding {
                if let object = cell.object, let index = objects.firstIndex(of: object) {
                    resIndex = index
                    
                    let createCell = self.delegate?.createCell?(object: object, table: self) ??
                        type(of: self).defaultDelegate?.createCell?(object: object, table: self)
                    if let cell = createCell as? TCell {
                        cell.cellFill?($0)
                    }
                }
            } else {
                resIndex = objects.firstIndex(of: $0)
            }
            if let index = resIndex {
                $0.separatorHidden = index == objects.count - 1 && self.table.tableFooterView != nil
            }
        }
    }
    
    @objc open func setNeedUpdateHeights() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateHeights), object: nil)
        perform(#selector(updateHeights), with: nil, afterDelay: 0)
    }
    
    @objc private func updateHeights() {
        if !visible {
            deferredUpdate = true
            return
        }
        if delegate != nil {
            table.beginUpdates()
            table.endUpdates()
        }
    }
    
    @objc open func editAction() {
        let complete = { [weak self] in
            if let wSelf = self {
                wSelf.table.setEditing(!wSelf.table.isEditing, animated: true)
                wSelf.reloadEditButton(animated: true)
            }
        }
        if let block = processEditing {
            block(complete)
        } else {
            complete()
        }
    }
    
    private func reloadEditButton(animated: Bool) {
        if let navigationItem = navigationItem {
            if noObjectsView.superview == nil {
                navigationItem.setRightBarButton(table.isEditing ? doneButton : editButton, animated: animated)
            } else {
                navigationItem.setRightBarButton(nil, animated: animated)
                table.setEditing(false, animated: animated)
            }
        }
    }
    
    private func createTable(style: UITableView.Style) {
        table = UITableView(frame: CGRect.zero, style: style)
        table.backgroundColor = UIColor.clear
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 150
        
        table.subviews.forEach {
            if let view = $0 as? UIScrollView {
                view.delaysContentTouches = false
            }
        }
    }
    
    func setup() {
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView()
        table.register(ContainerTableCell.self, forCellReuseIdentifier: "ContainerTableCell")
        noObjectsViewType = NoObjectsView.self
    }
    
    fileprivate func estimatedHeightKeyFor(object: Any) -> NSValue {
        return NSValue(nonretainedObject: object)
    }
    
    open override func responds(to aSelector: Selector!) -> Bool {
        if !super.responds(to: aSelector) {
            return delegate?.responds(to: aSelector) ?? false
        }
        return true
    }
    
    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if !super.responds(to: aSelector) {
            return delegate
        }
        return self
    }
    
    deinit {
        table.delegate = nil
        table.dataSource = nil
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateHeights), object: nil)
    }
}

extension Table: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = objects[indexPath.row]
        let safeCast = object as Any // swift bug workaround
        
        var cell: UITableViewCell!
        
        if let object = safeCast as? UITableViewCell {
            cell = object
        } else if let object = safeCast as? UIView {
            let tableCell = table.dequeueReusableCell(withIdentifier: "ContainerTableCell") as! ContainerTableCell
            
            if attachViewsByConstraints {
                tableCell.attach(view: object, useMargins: useMarginsForContainerCells)
            } else {
                tableCell.attachWithoutConstraint(view: object)
            }
            cell = tableCell
        } else {
            let createCell = (delegate?.createCell?(object: safeCast, table: self) ??
                type(of: self).defaultDelegate?.createCell?(object: safeCast, table: self))!
            
            if let createCell = createCell as? TCell {
                cell = tableView.dequeueReusableCell(withIdentifier: String(describing: createCell.cellType)) ?? createCell.cellType.loadFromNib()
                createCell.cellFill?(cell)
            }
        
            if let cell = cell as? TCellObjectHolding {
                cell.object = object
            }
        }
        
        cell.layoutIfNeeded()
        cell.separatorHidden = (indexPath.row == objects.count - 1) && table.tableFooterView != nil
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var resultHeight = UITableView.automaticDimension
        let object = objects[indexPath.row] as Any // swift bug workaround
        
        var height = delegate?.cellHeight?(object: object, def: resultHeight, table: self)
        if height == nil || height! == 0 {
            height = type(of: self).defaultDelegate?.cellHeight?(object: object, def: resultHeight, table: self)
        }
        if let height = height, height > 0 {
            resultHeight = height
        }
        
        return resultHeight
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let object = objects[indexPath.row] as Any // swift bug workaround
        
        if let cell = object as? UITableViewCell {
            return cell.bounds.size.height
        } else if let cell = object as? UIView {
            return cell.systemLayoutSizeFitting(CGSize(width: tableView.width, height: CGFloat.greatestFiniteMagnitude)).height
        } else if let value = estimatedHeights[estimatedHeightKeyFor(object: object)] {
            return value
        } else if let value = (delegate?.cellEstimatedHeight?(object: object, def: tableView.estimatedRowHeight, table: self) ??
            type(of: self).defaultDelegate?.cellEstimatedHeight?(object: object, def: tableView.estimatedRowHeight, table: self)) {
            return value
        }
        return 150
    }
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let object = objects[indexPath.row] as Any // swift bug workaround
        if let editor = ((delegate?.editable()?.cellEditor(object: object, table: self) ??
            type(of: self).defaultDelegate?.editable()?.cellEditor(object: object, table: self)) as? TEditor) {
            
            return editor.editingStyle != .none
        }
        return false
    }
}

extension Table: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = objects[indexPath.row] as Any // swift bug workaround
        
        var result = delegate?.action?(object: object, table: self)
        if result == nil || result! == .unsupported {
            result = type(of: self).defaultDelegate?.action?(object: object, table: self)
        }
        if result == nil || result! != .select {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let holding = cell as? TCellObjectHolding, let object = holding.object {
            estimatedHeights[estimatedHeightKeyFor(object: object)] = cell.bounds.size.height
        }
        delegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let object = objects[indexPath.row] as Any // swift bug workaround
        
        if let editor = ((delegate?.editable()?.cellEditor(object: object, table: self) ??
            type(of: self).defaultDelegate?.editable()?.cellEditor(object: object, table: self)) as? TEditor) {
            
            editor.action?()
        }
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let object = objects[indexPath.row] as Any // swift bug workaround
        if let editor = ((delegate?.editable()?.cellEditor(object: object, table: self) ??
            type(of: self).defaultDelegate?.editable()?.cellEditor(object: object, table: self)) as? TEditor) {
            
            if let actions = editor.actions?() {
                let configuration = UISwipeActionsConfiguration(actions: actions)
                configuration.performsFirstActionWithFullSwipe = false
                return configuration
            }
        }
        return nil
    }
    
    public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let object = objects[indexPath.row] as Any // swift bug workaround
        if let editor = ((delegate?.editable()?.cellEditor(object: object, table: self) ??
            type(of: self).defaultDelegate?.editable()?.cellEditor(object: object, table: self)) as? TEditor) {
            
            return editor.editingStyle
        }
        return .none
    }
}
