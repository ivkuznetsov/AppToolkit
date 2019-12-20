//
//  TabsView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc public enum TabsViewStyle: Int {
    case light
    case dark
}

@objcMembers
open class TabsView: UIView {
    
    open private(set) var stackView: UIStackView!
    
    var wasAddedToSuperview: (()->())?
    open var backgroundView: UIView
    private var selectedView: UIView
    open private(set) var selectedIndex: Int = 0
    private var didSelect: (UIButton, /* animated */ Bool)->()
    open private(set) var buttons: [TabsViewButton] = []
    open var selectorHeight: CGFloat = 2 {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var hiddenTabs: [Int] = [] {
        didSet {
            if hiddenTabs == oldValue {
                return
            }
            
            stackView.arrangedSubviews.forEach {
                stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            for (index, button) in buttons.enumerated() {
                if !hiddenTabs.contains(index) {
                    stackView.addArrangedSubview(button)
                }
            }
            if hiddenTabs.contains(selectedIndex), let availableButton = buttons.first(where: { !hiddenTabs.contains($0.tag) }) {
                selectTab(index: availableButton.tag, animated: false)
                didSelect(availableButton, false)
            } else {
                self.selectedView.frame = self.selectedFrame()
            }
        }
    }
    
    open override var frame: CGRect {
        willSet {
            stackView?.layoutMargins = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: -8)
        }
    }
    
    open override func didMoveToSuperview() {
        if superview != nil {
            wasAddedToSuperview?()
        }
    }
    
    public init(titles: [String], style: TabsViewStyle, didSelect: @escaping (UIButton, Bool)->()) {
        self.didSelect = didSelect
        
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.clear
        
        selectedView = UIView()
        
        super.init(frame: CGRect.zero)
        for (index, title) in titles.enumerated() {
            let button = TabsViewButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
            button.tintColor = style == .dark ? UIColor.white : UIColor.black
            button.addTarget(self, action: #selector(selectAction(_:)), for: .touchUpInside)
            button.tag = index
            buttons.append(button)
        }
        
        stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        self.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addConstraint(NSLayoutConstraint(item: stackView!, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: stackView!, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: -3))
        self.addConstraint(NSLayoutConstraint(item: stackView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: stackView!, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        
        let color = UIColor(red: 226.0 / 255.0, green: 225.0 / 255.0, blue: 229.0 / 255.0, alpha: 1.0)
        if style == .light {
            self.backgroundColor = color.withAlphaComponent(0.3)
        }
        self.addSubview(backgroundView)
        
        selectedView.backgroundColor = tintColor
        backgroundView.addSubview(selectedView)
    }
    
    open override var tintColor: UIColor! {
        didSet {
            selectedView.backgroundColor = tintColor
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = CGRect(x: stackView.layoutMargins.left, y: self.bounds.size.height - selectorHeight, width: stackView.width - stackView.layoutMargins.left - stackView.layoutMargins.right, height: selectorHeight)
        selectedView.frame = selectedFrame()
    }
    
    private func selectedFrame() -> CGRect {
        if stackView.arrangedSubviews.count == 0 {
            return CGRect.zero
        }
        guard let index = stackView?.arrangedSubviews.firstIndex(of: buttons[selectedIndex]) else {
            return CGRect.zero
        }
        let width = backgroundView.width / CGFloat(stackView!.arrangedSubviews.count)
        return CGRect(x: width * CGFloat(index), y: 0, width: width, height: backgroundView.height)
    }
    
    @objc private func selectAction(_ sender: UIButton) {
        selectTab(index: sender.tag, animated: true)
        didSelect(sender, true)
    }
    
    open func selectTab(index: Int, animated: Bool) {
        selectedIndex = index
        UIView.animate(withDuration: animated ? 0.2 : 0.0) {
            self.selectedView.frame = self.selectedFrame()
        }
    }
    
    open func selectNext(animated: Bool) -> Int? {
        let nextIndex: Int? = (selectedIndex...buttons.count - 1).first { !hiddenTabs.contains($0) && $0 != selectedIndex && buttons[$0].isEnabled }
        
        if let nextIndex = nextIndex {
            selectTab(index: nextIndex, animated: animated)
        }
        return nextIndex
    }
    
    open func selectPrevious(animated: Bool) -> Int? {
        let prevIndex: Int? = (0...selectedIndex).reversed().first { !hiddenTabs.contains($0) && $0 != selectedIndex && buttons[$0].isEnabled }
        
        if let prevIndex = prevIndex {
            selectTab(index: prevIndex, animated: animated)
        }
        return prevIndex
    }
}
