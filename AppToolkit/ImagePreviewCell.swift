//
//  ImagePreviewCell.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 2/8/21.
//  Copyright © 2021 Ilya Kuznetsov. All rights reserved.
//

import UIKit

class ImagePreviewCell: UICollectionViewCell {
    
    public let scrollView = PreviewScrollView()
    
    var item: ImagePreviewController.Item! {
        didSet {
            if let image = item.previewImage {
                scrollView.set(image: image)
            } else {
                let item = self.item
                
                scrollView.set(image: nil)
                
                if let loader = item?.previewLoader {
                    
                    loader({ [weak self] image in
                        if self?.scrollView.imageView.image == nil && self?.item.uid == item?.uid {
                            self?.scrollView.set(image: image)
                        }
                    })
                }
            }
            if let loader = item.bigImageLoader {
                loader({ [weak self] image in
                    self?.scrollView.set(image: image, resize: false)
                })
            }
        }
    }
    
    func set(item: ImagePreviewController.Item, aspectFill: Bool) {
        scrollView.aspectFill = aspectFill
        self.item = item
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scrollView)
        scrollView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
}
