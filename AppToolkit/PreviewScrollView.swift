//
//  PreviewScrollView.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 9/2/20.
//  Copyright © 2020 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATPreviewScrollView)
open class PreviewScrollView: UIScrollView, UIScrollViewDelegate {
    
    @IBInspectable public var aspectFill: Bool = false
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.layer.allowsEdgeAntialiasing = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    public let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    public var didZoom: ((CGFloat)->())?
    public var didScroll: (()->())?
    public var didEndScroll: (()->())?
    public var didZoomContinuous: (()->())?
    public var customizeInsetsOnZoom: ((UIEdgeInsets)->(UIEdgeInsets))?
    public var minAspectLimit: CGFloat?
    public var maxAspectLimit: CGFloat?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        delegate = self
        clipsToBounds = false
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
    }
    
    open func set(image: UIImage?) {
        set(image: image, aspect: aspect(size: self.size(image: image)))
    }
    
    private func size(image: UIImage?) -> CGSize {
        if let image = image {
            return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        }
        return .zero
    }
    
    private func aspect(size: CGSize) -> CGFloat {
        if size.width > 0 {
            return size.height / size.width
        }
        return 0
    }
    
    private func set(image: UIImage?, aspect: CGFloat) {
        let size = self.size(image: image)
        
        imageView.image = image
        
        if imageView.superview == nil {
            imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            containerView.addSubview(imageView)
            insertSubview(containerView, at: 0)
        }
        
        if image != nil {
            minimumZoomScale = 1
            maximumZoomScale = 1
            zoomScale = 1
            layoutIfNeeded()
            
            let scale = UIScreen.main.scale
            
            containerView.frame = CGRect(x: 0, y: 0, width: size.width / scale, height: size.height / scale)
            imageView.frame = containerView.frame
            contentSize = imageView.bounds.size
            layoutImageView()
            zoomScale = minimumZoomScale
            scrollViewDidZoom(self)
            
            if aspectFill {
                contentOffset = CGPoint(x: contentSize.width / 2 - bounds.size.width / 2, y: contentSize.height / 2 - bounds.size.height / 2)
            }
        }
    }
    
    public func zoomToFill() {
        if containerView.frame.size.height == 0 || bounds.size.height == 0 || imageView.frame.size.width == 0 || imageView.frame.size.height == 0 {
            return
        }
        
        let aspect = (containerView.frame.size.width / zoomScale) / (containerView.frame.size.height / zoomScale)
        let viewAspect = bounds.size.width / bounds.size.height
        
        if aspect < viewAspect {
            zoomScale = bounds.size.width / (imageView.frame.size.width / zoomScale)
        } else {
            zoomScale = bounds.size.height / (imageView.frame.size.height / zoomScale)
        }
        contentOffset = CGPoint(x: contentSize.width / 2 - bounds.size.width / 2, y: contentSize.height / 2 - bounds.size.height / 2)
    }
    
    private func layoutImageView() {
        if imageView.image == nil || bounds.size.width == 0 || bounds.size.height == 0 {
            return
        }
        
        maximumZoomScale = 4
        
        var aspect = (containerView.frame.size.width / zoomScale) / (containerView.frame.size.height / zoomScale)
        
        if let minAspectLimit = minAspectLimit {
            aspect = max(aspect, minAspectLimit)
        }
        if let maxAspectLimit = maxAspectLimit {
            aspect = min(aspect, maxAspectLimit)
        }
        
        let viewAspect = bounds.size.width / bounds.size.height
        
        if (!aspectFill && aspect > viewAspect) || (aspectFill && aspect < viewAspect) {
            minimumZoomScale = bounds.size.width / (imageView.frame.size.height * aspect / zoomScale)
        } else {
            minimumZoomScale = bounds.size.height / (imageView.frame.size.width / aspect / zoomScale)
        }
        
        if maximumZoomScale < minimumZoomScale {
            maximumZoomScale = minimumZoomScale
        }
        if zoomScale < minimumZoomScale {
            zoomScale = minimumZoomScale
        }
        if zoomScale > maximumZoomScale {
            zoomScale = maximumZoomScale
        }
    }
    
    open override var frame: CGRect {
        didSet {
            if oldValue != frame {
                layoutImageView()
                zoomScale = minimumZoomScale
                scrollViewDidZoom(self)
            }
        }
    }
    
    open override var bounds: CGRect {
        didSet {
            if oldValue.size != bounds.size {
                layoutImageView()
                scrollViewDidZoom(self)
            }
        }
    }
    
    open var croppingRect: CGRect {
        set {
            var newRect = newValue
            newRect.origin.x /= UIScreen.main.scale
            newRect.origin.y /= UIScreen.main.scale
            newRect.size.width /= UIScreen.main.scale
            newRect.size.height /= UIScreen.main.scale
            zoomScale = frame.size.width / newRect.size.width
            newRect.origin.x *= zoomScale
            newRect.origin.y *= zoomScale
            setContentOffset(newRect.origin, animated: false)
        }
        get {
            var newRect = convert(bounds, to: imageView)
            newRect.origin.x *= UIScreen.main.scale
            newRect.origin.y *= UIScreen.main.scale
            newRect.size.width *= UIScreen.main.scale
            newRect.size.height *= UIScreen.main.scale
            return newRect
        }
    }
    
    open var croppedImage: UIImage? {
        if let image = imageView.image, let imageRef = image.cgImage?.cropping(to: croppingRect) {
            return UIImage(cgImage: imageRef)
        }
        return nil
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        var top: CGFloat = 0
        var left: CGFloat = 0
        
        if contentSize.width < bounds.size.width {
            left = (bounds.size.width - contentSize.width) * 0.5
        }
        if contentSize.height < bounds.size.height {
            top = (bounds.size.height - contentSize.height) * 0.5
        }
        let insets = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
        scrollView.contentInset = customizeInsetsOnZoom?(insets) ?? insets
        didZoomContinuous?()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndScroll?()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        didZoom?(scale)
    }
}
