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
    
    private let animation: ExpandAnimation
    
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
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView]))
        
        scrollView.set(image: image)
        animation.viewController = self
        self.transitioningDelegate = animation
        
        scrollView.didZoom = { [weak self] (zoom) in
            if let wSelf = self {
                wSelf.animation.interactionDismissing = zoom <= wSelf.scrollView.minimumZoomScale
            }
        }
        scrollView.didZoom?(scrollView.zoomScale)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
