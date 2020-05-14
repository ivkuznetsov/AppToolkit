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
    
    open var image: UIImage
    open var scrollView: ATPreviewScrollView!
    
    private var sourceView: UIView
    private var customContainer: UIView?
    private var animation: ExpandAnimation!
    private var contentMode: UIView.ContentMode
    
    public init(image: UIImage, sourceView: UIView, customContainer: UIView?, contentMode: UIView.ContentMode) {
        self.image = image
        self.sourceView = sourceView
        self.customContainer = customContainer
        self.contentMode = contentMode
        super.init()
        
        if #available(iOS 13, *) {
            modalPresentationStyle = .fullScreen
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = ATPreviewScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView!]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: ["scrollView" : scrollView!]))
        
        scrollView.setImage(image)
        animation = ExpandAnimation(source: sourceView, dismissingSource: scrollView.imageView, customContainer: customContainer, viewController: self, contentMode: contentMode)
        self.transitioningDelegate = animation
        
        scrollView.didZoom = { [weak self] (zoom) in
            if let wSelf = self {
                wSelf.animation.interactionDismissing = zoom <= wSelf.scrollView.minimumZoomScale
            }
        }
        scrollView.didZoom(scrollView.zoomScale)
        
        if customContainer != nil {
            scrollView?.backgroundColor = sourceView.backgroundColor
            scrollView.imageView?.backgroundColor = sourceView.backgroundColor
            scrollView.containerView?.backgroundColor = sourceView.backgroundColor
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
