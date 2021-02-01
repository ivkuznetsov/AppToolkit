//
//  ExpandAnimation.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATExpandAnimation)
open class ExpandAnimation: NSObject {
    
    fileprivate let source: UIView
    fileprivate let dismissingSource: UIImageView
    fileprivate let customContainer: UIView?
    weak var viewController: UIViewController?
    fileprivate var yTranslation: CGFloat = 0
    fileprivate var reversed: Bool = false
    fileprivate var location = CGPoint.zero
    fileprivate var interativeContext: UIViewControllerContextTransitioning?
    fileprivate var shouldEndGesture = false
    public var allowTapToClose: Bool = true {
        didSet {
            if tapGR.isEnabled && !allowTapToClose {
                tapGR.isEnabled = false
            }
        }
    }
    
    public var interactionDismissing = false {
        didSet {
            if interactionDismissing {
                dismissingSource.superview?.superview?.addGestureRecognizer(panGR)
                dismissingSource.superview?.superview?.addGestureRecognizer(pinchGR)
                panGR.isEnabled = true
                pinchGR.isEnabled = true
            } else {
                panGR.isEnabled = false
                pinchGR.isEnabled = false
            }
            dismissingSource.superview?.superview?.addGestureRecognizer(tapGR)
            tapGR.isEnabled = allowTapToClose
        }
    }
    
    fileprivate let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    
    fileprivate let secondImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()
    
    public let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    fileprivate var pinchGR: UIPinchGestureRecognizer!
    fileprivate var panGR: UIPanGestureRecognizer!
    public var tapGR: UITapGestureRecognizer!
    fileprivate let contentMode: UIView.ContentMode
    var presenting: Bool = false
    
    init(source: UIView, dismissingSource: UIImageView, customContainer: UIView?, contentMode: UIView.ContentMode) {
        self.source = source
        self.dismissingSource = dismissingSource
        self.customContainer = customContainer
        self.contentMode = contentMode
        super.init()
        
        pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinchGR.delegate = self
        panGR = UIPanGestureRecognizer(target: self, action: #selector(panAction(_:)))
        panGR.delegate = self
        tapGR = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGR.delegate = self
        tapGR.require(toFail: pinchGR)
        tapGR.require(toFail: panGR)
        
        imageView.contentMode = contentMode
        secondImageView.contentMode = contentMode
        
        if customContainer != nil {
            imageView.backgroundColor = source.backgroundColor
            secondImageView.backgroundColor = source.backgroundColor
            overlayView.backgroundColor = source.backgroundColor
        }
    }
    
    @objc func panAction(_ gr: UIPanGestureRecognizer) {
        let translation = gr.translation(in: dismissingSource.superview?.superview)
        
        if gr.state == .began {
            viewController?.dismiss(animated: true, completion: nil)
            yTranslation = translation.y
        }
        if gr.state == .changed {
            
            let value = min(1, (1 - (translation.y / dismissingSource.superview!.superview!.height) / 2))
            let scale = max(value, 0.7)
            
            var convertedTranslation = translation
            convertedTranslation.x = abs(translation.x) < 25 ? abs(translation.x) : (sqrt(abs(convertedTranslation.x)) * 5)
            if translation.x < 0 {
                convertedTranslation.x = -convertedTranslation.x
            }
            if translation.y < 0 {
                convertedTranslation.y = translation.y > -25 ? translation.y : (-sqrt(abs(convertedTranslation.y)) * 5)
            }
            imageView.transform = CGAffineTransform(translationX: convertedTranslation.x, y: convertedTranslation.y).concatenating(CGAffineTransform(scaleX: scale, y: scale))
            overlayView.alpha = value
            reversed = yTranslation > translation.y
        }
        if gr.state == .cancelled || gr.state == .ended {
            endGesture()
        }
        yTranslation = translation.y
    }
    
    @objc func pinchAction(_ gr: UIPinchGestureRecognizer) {
        if gr.state == .began {
            viewController?.dismiss(animated: true, completion: nil)
            location = gr.location(in: dismissingSource.superview?.superview)
        }
        if gr.state == .changed {
            if gr.numberOfTouches < 2 {
                gr.isEnabled = false
                gr.isEnabled = true
                return
            }
            let scale = pinchGR.scale
            let location = gr.location(in: dismissingSource.superview?.superview)
            let translation = CGPoint(x: location.x - self.location.x, y: location.y - self.location.y)
            
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: translation.x, y: translation.y))
            overlayView.alpha = scale
            reversed = pinchGR.velocity > 0 && scale > 0.4
        }
        if gr.state == .cancelled || gr.state == .ended {
            endGesture()
        }
    }
    
    func endGesture() {
        if let context = interativeContext {
            if reversed {
                cancelInteraction()
            } else {
                dismissController(context: context)
                interativeContext = nil
            }
        } else {
            shouldEndGesture = true
        }
    }
    
    func cancelInteraction() {
        if let context = interativeContext {
            let toVC = context.viewController(forKey: .to)
            let containerView = context.containerView
            
            context.cancelInteractiveTransition()
            
            let frame = imageView.frame
            imageView.transform = .identity
            imageView.frame = frame
            
            UIView.animate(withDuration: transitionDuration(using: context) * 2 / 3,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 2,
                           options: .curveEaseOut,
                           animations: {
                            
                            self.overlayView.alpha = 1
                            self.imageView.frame = self.dismissingSource.convert(self.dismissingSource.bounds, to: containerView)
            }, completion: { (_) in
                
                self.source.isHidden = false
                self.imageView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                toVC?.view.removeFromSuperview()
                self.interativeContext?.completeTransition(false)
            })
        }
    }
    
    @objc func tapAction(_ gr: UITapGestureRecognizer) {
        interactionDismissing = false
        viewController?.dismiss(animated: true, completion: nil)
    }
}

extension ExpandAnimation: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        if panGR.state != .changed && panGR.state != .began && pinchGR.state != .changed && pinchGR.state != .began {
            interactionDismissing = false
        }
        return self
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionDismissing ? self : nil
    }
}

extension ExpandAnimation: UIViewControllerInteractiveTransitioning {
    
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        interativeContext = transitionContext
        
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let containerView = transitionContext.containerView
        let finalFrane = transitionContext.finalFrame(for: toVC)
        
        toVC.view.frame = finalFrane
        containerView.addSubview(toVC.view)
        
        overlayView.frame = fromVC.view.bounds
        overlayView.alpha = 1
        containerView.addSubview(overlayView)
        
        imageView.image = dismissingSource.image
        imageView.frame = dismissingSource.convert(dismissingSource.bounds, to: containerView)
        source.isHidden = true
        containerView.addSubview(imageView)
        
        if shouldEndGesture {
            shouldEndGesture = false
            endGesture()
        }
    }
}

extension UIView {
    
    func findTabbar() -> UITabBar? {
        var responder: UIResponder = self
        
        while responder.next != nil {
            responder = responder.next!
            if var vc = responder as? UIViewController {
                
                while vc.parent != nil {
                    if let vc = vc as? UITabBarController {
                        return vc.tabBar
                    }
                    vc = vc.parent!
                }
            }
        }
        return nil
    }
    
    func findViewController() -> UIViewController? {
        var responder: UIResponder = self
        
        while responder.next != nil {
            responder = responder.next!
            if let vc = responder as? UIViewController {
                return vc
            }
        }
        return nil
    }
}

extension ExpandAnimation: UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.45
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)
        
        if presenting {
            source.isHidden = true
            
            toVC.view.frame = finalFrame
            
            overlayView.frame = finalFrame
            overlayView.alpha = 0
            containerView.addSubview(overlayView)
            
            var customOverlay: UIView?
            if let container = customContainer {
                customOverlay = container.snapshotView(afterScreenUpdates: true)
                
                let view = UIView(frame: customOverlay!.frame)
                view.addSubview(customOverlay!)
                view.backgroundColor = UIColor.clear
                view.clipsToBounds = true
                view.frame = container.convert(container.bounds, to: containerView)
                view.height = min(containerView.height - view.y, view.height)
                
                if let tabbar = container.findTabbar() {
                    view.height -= tabbar.height
                }
                
                let vc = customContainer?.findViewController()
                
                var offset = view.y
                if vc?.navigationController?.isNavigationBarHidden == false, let navbar = vc?.navigationController?.navigationBar {
                    offset -= navbar.y + navbar.height
                }
                
                customOverlay!.y = offset
                view.y -= offset
                view.height += offset
                
                customOverlay = view
            }
            
            let oldColor = toVC.view.subviews.first?.backgroundColor
            toVC.view.subviews.first?.backgroundColor = UIColor.clear
            imageView.image = dismissingSource.image
            toVC.view.subviews.first?.backgroundColor = oldColor
            imageView.frame = source.convert(source.bounds, to: containerView)
            containerView.addSubview(imageView)
            
            if let overlay = customOverlay {
                containerView.addSubview(overlay)
            }
            
            secondImageView.image = imageView.image
            secondImageView.frame = imageView.convert(imageView.bounds, to: source.superview)
            
            source.superview?.addSubview(secondImageView)
            
            imageView.alpha = 0
            
            var targetRect = finalFrame
            if let imageSize = imageView.image?.size {
                let scale = min(finalFrame.size.width / imageSize.width, finalFrame.size.height / imageSize.height)
                targetRect.size = CGSize(width:imageSize.width * scale, height: imageSize.height * scale)
                targetRect.origin = CGPoint(x: (finalFrame.size.width - targetRect.size.width) / 2, y: (finalFrame.size.height - targetRect.size.height) / 2)
            }
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 2,
                           options: .curveEaseOut,
                           animations: {
                            
                            self.imageView.frame = targetRect
                            self.imageView.alpha = 1
                            if let frame = self.imageView.superview?.convert(targetRect, to: self.secondImageView.superview) {
                                self.secondImageView.frame = frame
                            }
            }, completion: { (_) in
                
                self.source.isHidden = false
                containerView.addSubview(toVC.view)
                self.imageView.removeFromSuperview()
                self.overlayView.removeFromSuperview()
                self.secondImageView.removeFromSuperview()
                customOverlay?.removeFromSuperview()
                transitionContext.completeTransition(true)
            })
            UIView.animate(withDuration: transitionDuration(using: transitionContext) * 2 / 3, delay: transitionDuration(using: transitionContext) / 3, options: [], animations: {
                
                customOverlay?.alpha = 0.0
                self.overlayView.alpha = 1
            }, completion: nil)
            
        } else {
            toVC.view.frame = finalFrame
            containerView.addSubview(toVC.view)
            
            overlayView.frame = fromVC.view.bounds
            overlayView.alpha = 1
            containerView.addSubview(overlayView)
            
            imageView.image = dismissingSource.image
            imageView.frame = dismissingSource.convert(dismissingSource.bounds, to: containerView)
            containerView.addSubview(imageView)
            
            dismissController(context: transitionContext)
        }
    }
    
    func dismissController(context: UIViewControllerContextTransitioning) {
        let fromVC = context.viewController(forKey: .from)!
        fromVC.view.removeFromSuperview()
        let containerView = context.containerView
        context.finishInteractiveTransition()
        
        let frame = imageView.frame
        imageView.transform = .identity
        imageView.frame = frame
        source.isHidden = true
        
        var customOverlay: UIView?
        if let container = customContainer {
            customOverlay = container.snapshotView(afterScreenUpdates: true)
            
            let view = UIView(frame: customOverlay!.frame)
            view.addSubview(customOverlay!)
            view.backgroundColor = UIColor.clear
            view.clipsToBounds = true
            view.frame = container.convert(container.bounds, to: containerView)
            view.height = min(containerView.height - view.y, view.height)
            
            if let tabbar = container.findTabbar() {
                view.height -= tabbar.height
            }
            
            let vc = customContainer?.findViewController()
            
            var offset = view.y
            if vc?.navigationController?.isNavigationBarHidden == false, let navbar = vc?.navigationController?.navigationBar {
                offset -= navbar.y + navbar.height
            }
            
            customOverlay!.y = offset
            view.y -= offset
            view.height += offset
            
            customOverlay = view
            containerView.addSubview(customOverlay!)
            customOverlay!.alpha = 0
        }
        
        secondImageView.image = imageView.image
        secondImageView.frame = imageView.convert(imageView.bounds, to: source.superview)
        source.superview?.addSubview(secondImageView)
        
        UIView.animate(withDuration: transitionDuration(using: context),
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 2,
                       options: .curveEaseOut,
                       animations: {
                        
                        self.imageView.frame = self.source.convert(self.source.bounds, to: containerView)
                        self.secondImageView.frame = self.source.convert(self.source.bounds, to: self.secondImageView.superview!)
                        self.imageView.layer.cornerRadius = self.source.layer.cornerRadius
                        self.secondImageView.layer.cornerRadius = self.source.layer.cornerRadius
                        
                        if let overlay = customOverlay {
                            overlay.alpha = 1
                        } else {
                            self.imageView.alpha = 0
                        }
                        
        }) { (_) in
            
            self.source.isHidden = false
            DispatchQueue.main.async {
                self.imageView.removeFromSuperview()
                self.imageView.alpha = 1
                self.secondImageView.removeFromSuperview()
                if let overlay = customOverlay {
                    overlay.removeFromSuperview()
                } else {
                    self.source.superview?.addFadeTransition()
                }
                context.completeTransition(true)
            }
        }
        UIView.animate(withDuration: transitionDuration(using: context) / 3.0) {
            self.overlayView.alpha = 0
        }
    }
}

extension ExpandAnimation: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != pinchGR || pinchGR.scale < 1.0
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != pinchGR && gestureRecognizer != panGR
    }
}
