//
//  LoadingBarView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATLoadingBarView)
open class LoadingBarView: UIView {
    
    @objc open var fillColor: UIColor = UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0) {
        didSet {
            fillLayer.strokeColor = fillColor.cgColor
        }
    }
    
    open override var tintColor: UIColor! {
        didSet {
            fillColor = tintColor
        }
    }
    
    @objc open var clipColor: UIColor = UIColor(white: 1.0, alpha: 0.6) {
        didSet {
            clipLayer.strokeColor = clipColor.cgColor
        }
    }
    
    private lazy var fillLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = fillColor.cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.fillColor = UIColor.clear.cgColor
        layer.backgroundColor = UIColor(white:0.0, alpha:0.05).cgColor
        self.layer.addSublayer(layer)
        return layer
    }()
    
    private lazy var clipLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = tintColor.cgColor
        layer.lineCap = CAShapeLayerLineCap.round
        layer.fillColor = UIColor.clear.cgColor
        layer.backgroundColor = UIColor(white:0.0, alpha:0.05).cgColor
        self.fillLayer.addSublayer(layer)
        return layer
    }()
    
    @objc open var progress: CGFloat = 0 {
        didSet {
            infinite = false
            fillLayer.strokeEnd = progress
            if progress <= oldValue {
                fillLayer.removeAnimation(forKey: "strokeEnd")
            }
        }
    }
    
    @objc open var infinite: Bool = true {
        didSet {
            clipLayer.isHidden = !infinite
            if infinite {
                startAnimation()
            } else {
                clipLayer.removeAllAnimations()
            }
        }
    }
    
    public required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc open class func present(in view: UIView, animated: Bool) -> Self {
        let barView = self.init(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 3))
        view.addSubview(barView)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let next = view.next
        if let next = next as? UIViewController {
            barView.translatesAutoresizingMaskIntoConstraints = false
            
            view.leftAnchor.constraint(equalTo: barView.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: barView.rightAnchor).isActive = true
            barView.topAnchor.constraint(equalTo: next.view.safeAreaLayoutGuide.topAnchor).isActive = true
            barView.heightAnchor.constraint(equalToConstant: 3).isActive = true
        }
        
        if animated {
            barView.alpha = 0
            UIView.animate(withDuration: 0.15, animations: {
                barView.alpha = 1.0
            })
        }
        return barView
    }
    
    @objc open func hide(_ animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
            }, completion: { (_) in
                self.removeFromSuperview()
            })
        }
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        fillLayer.frame = bounds
        clipLayer.frame = fillLayer.bounds
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.size.height / 2.0))
        path.addLine(to: CGPoint(x: bounds.size.width, y: bounds.size.height / 2.0))
        fillLayer.path = path.cgPath
        fillLayer.lineWidth = bounds.size.height
        clipLayer.lineWidth = bounds.size.height
        
        clipLayer.path = startPath()
    }
    
    private func startPath() -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.size.height / 2.0))
        
        var offset: CGFloat = -16.0
        
        while offset < self.bounds.size.width {
            path.move(to: CGPoint(x: offset, y: bounds.size.height / 2.0))
            path.addLine(to: CGPoint(x: offset + 6, y: bounds.size.height / 2.0))
            offset += 16
        }
        return path.cgPath
    }
    
    private func toPath() -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.size.height / 2.0))
        
        var offset: CGFloat = 0
        
        while offset < bounds.size.width + 16 {
            path.move(to: CGPoint(x: offset, y: bounds.size.height / 2.0))
            path.addLine(to: CGPoint(x: offset + 6, y: bounds.size.height / 2.0))
            offset += 16
        }
        return path.cgPath
    }
    
    private func startAnimation() {
        if clipLayer.animation(forKey: "animation") != nil {
            return
        }
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = startPath()
        animation.toValue = toPath()
        animation.duration = 0.2
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.repeatCount = HUGE
        clipLayer.add(animation, forKey: "animation")
    }
    
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        
        if self.superview != nil && infinite {
            startAnimation()
        } else {
            clipLayer.removeAllAnimations()
        }
    }
}
