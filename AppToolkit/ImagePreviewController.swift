//
//  ImagePreviewController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATImagePreviewController)
open class ImagePreviewController: BaseController, CollectionDelegate {
    
    public class Item: Hashable {
        let uid = UUID().uuidString
        
        public var previewImage: UIImage?
        var previewLoader: (( @escaping (UIImage)->() )->())?
        var bigImageLoader: (( @escaping (UIImage)->() )->())?
        
        public init(previewImage: UIImage? = nil,
                    previewLoader: (( @escaping (UIImage)->() )->())? = nil,
                    bigImageLoader: (( @escaping (UIImage)->() )->())? = nil) {
            self.previewImage = previewImage
            self.previewLoader = previewLoader
            self.bigImageLoader = bigImageLoader
        }
        
        public static func == (lhs: ImagePreviewController.Item, rhs: ImagePreviewController.Item) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(uid)
        }
    }
    
    public let items: [Item]
    private let aspectFill: Bool
    private weak var currentVisibleCell: ImagePreviewCell? {
        didSet {
            if let cell = currentVisibleCell, cell != oldValue {
                cell.scrollView.didZoom = { [weak self, weak cell] (zoom) in
                    if let wSelf = self, let cell = cell {
                        wSelf.animation?.interactionDismissing = zoom <= cell.scrollView.minimumZoomScale && wSelf.allowInteractiveDismissing
                    }
                }
                if let animation = animation {
                    cell.scrollView.panGestureRecognizer.require(toFail: animation.panGR)
                }
                oldValue?.scrollView.didZoom = nil
                
                cell.scrollView.didZoom?(cell.scrollView.zoomScale)
            }
        }
    }
    
    public var scrollView: PreviewScrollView? {
        return currentVisibleCell?.scrollView
    }
    
    public var animation: ExpandAnimation?
    public var allowInteractiveDismissing = true {
        didSet {
            if let scrollView = currentVisibleCell?.scrollView {
                scrollView.didZoom?(scrollView.zoomScale)
            }
        }
    }
    
    public var collection: Collection!
    private let sourceView: (Item)->UIView?
    private let initialIndex: Int?
    
    convenience public init(image: UIImage, sourceView: UIView, customContainer: UIView? = nil, aspectFill: Bool) {
        self.init(items: [Item(previewImage: image)], sourceView: { (_) in sourceView }, customContainer: customContainer, aspectFill: aspectFill)
    }
    
    public init(items: [Item], initialIndex: Int? = nil, sourceView: @escaping (Item)->UIView?, customContainer: UIView? = nil, aspectFill: Bool) {
        self.items = items
        self.initialIndex = initialIndex
        self.aspectFill = aspectFill
        self.sourceView = sourceView
        super.init()
        
        if #available(iOS 13, *) {
            modalPresentationStyle = .fullScreen
        }
    }
    
    public init(image: UIImage, aspectFill: Bool) {
        self.items = [Item(previewImage: image)]
        self.aspectFill = aspectFill
        self.sourceView = { (_) in nil }
        self.initialIndex = nil
        super.init()
        
        if #available(iOS 13, *) {
            modalPresentationStyle = .fullScreen
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        collection = Collection(view: view, delegate: self)
        collection.collection.setCollectionViewLayout(UICollectionViewFlowLayout(), animated: false)
        collection.layout?.minimumLineSpacing = 0
        collection.layout?.minimumInteritemSpacing = 0
        collection.layout?.scrollDirection = .horizontal
        collection.collection.isPagingEnabled = true
        collection.collection.contentInsetAdjustmentBehavior = .never
        collection.collection.alwaysBounceVertical = false
        collection.collection.alwaysBounceHorizontal = false
        collection.collection.showsVerticalScrollIndicator = false
        collection.collection.showsHorizontalScrollIndicator = false
        
        if let source = sourceView(items[initialIndex ?? 0]) {
            var fill = aspectFill
            if let view = source as? UIImageView {
                fill = view.contentMode == .scaleAspectFill
            }
            
            animation = ExpandAnimation(source: { [weak self] in
                
                if let wSelf = self  {
                    return wSelf.sourceView(wSelf.currentVisibleCell?.item ?? wSelf.items[wSelf.initialIndex ?? 0])
                }
                return nil
                
            }, dismissingImageView: { [weak self] () -> (UIImageView?) in
                return self?.currentVisibleCell?.scrollView.imageView
            }, gesturesView: collection.collection, aspectFill: fill)
            
            collection.collection.panGestureRecognizer.require(toFail: animation!.panGR)
            animation!.viewController = self
            animation!.overlayView.backgroundColor = .black
            self.transitioningDelegate = animation
        }
    }
    
    private var appeared = false
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
        UIView.animate(withDuration: 0.15) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        appeared = false
        setNeedsStatusBarAppearanceUpdate()
        super.viewWillDisappear(animated)
    }
    
    open override var prefersStatusBarHidden: Bool { appeared }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    open override func performOnFirstLayout() {
        super.performOnFirstLayout()
        
        if let index = initialIndex {
            collection.collection.contentOffset = CGPoint(x: collection.collection.width * CGFloat(index), y: 0)
        }
        collection.set(objects: items, animated: false)
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func createCell(object: Any, collection: Collection) -> Any? {
        if let object = object as? Item {
            return CCell(ImagePreviewCell.self) {
                $0.set(item: object, aspectFill: self.aspectFill)
                
                if let animation = self.animation {
                    $0.scrollView.pinchGestureRecognizer?.require(toFail: animation.pinchGR)
                    
                    if animation.customContainer != nil, let source = animation.source() {
                        $0.scrollView.backgroundColor = source.backgroundColor
                        $0.scrollView.imageView.backgroundColor = source.backgroundColor
                        $0.scrollView.containerView.backgroundColor = source.backgroundColor
                    }
                }
            }
        }
        return nil
    }
    
    public func cellSizeFor(object: Any, collection: Collection) -> CGSize {
        return view.size
    }
    
    private func reloadCurrentCell() {
        let centerX = collection.collection.contentOffset.x + collection.collection.width / 2
        
        var cell: ImagePreviewCell?
        
        collection.collection.visibleCells.forEach {
            if cell == nil || abs(centerX - (cell!.origin.x + cell!.size.width / 2)) > abs(centerX - ($0.origin.x + $0.size.width / 2)) {
                cell = $0 as? ImagePreviewCell
            }
        }
        currentVisibleCell = cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if currentVisibleCell == nil {
            currentVisibleCell = cell as? ImagePreviewCell
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        reloadCurrentCell()
    }
}
