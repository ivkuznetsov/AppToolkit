//
//  ImagePreviewController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATImagePreviewController)
open class ImagePreviewController: BaseController {
    
    public let image: UIImage
    public let scrollView = PreviewScrollView()
    
    public let animation: ExpandAnimation?
    public var allowInteractiveDismissing = true {
        didSet {
            scrollView.didZoom?(scrollView.zoomScale)
        }
    }
    
    public init(image: UIImage, sourceView: UIView, customContainer: UIView?, contentMode: UIView.ContentMode) {
        self.image = image
        animation = ExpandAnimation(source: sourceView, dismissingSource: scrollView.imageView, customContainer: customContainer, contentMode: contentMode)
        super.init()
        
        if customContainer != nil {
            scrollView.backgroundColor = sourceView.backgroundColor
            scrollView.imageView.backgroundColor = sourceView.backgroundColor
            scrollView.containerView.backgroundColor = sourceView.backgroundColor
        }
        
        if #available(iOS 13, *) {
            modalPresentationStyle = .fullScreen
        }
    }
    
    public init(image: UIImage, aspectFill: Bool) {
        self.image = image
        animation = nil
        scrollView.aspectFill = aspectFill
        super.init()
        
        if #available(iOS 13, *) {
            modalPresentationStyle = .fullScreen
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        scrollView.set(image: image)
        
        if let animation = animation {
            animation.viewController = self
            self.transitioningDelegate = animation
            
            scrollView.didZoom = { [weak self] (zoom) in
                if let wSelf = self {
                    wSelf.animation?.interactionDismissing = zoom <= wSelf.scrollView.minimumZoomScale && wSelf.allowInteractiveDismissing
                }
            }
            scrollView.didZoom?(scrollView.zoomScale)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
