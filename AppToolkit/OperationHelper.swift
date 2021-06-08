//
//  OperationHelper.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 12/20/19.
//  Copyright © 2019 Ilya Kuznetsov. All rights reserved.
//

import UIKit

@objc(ATLoadingType)
public enum LoadingType: Int {
    case fullscreen
    case translucent
    case touchable
    case none
}

@objc(ATCancellable)
public protocol Cancellable {
    func cancel()
}

extension URLSessionTask: Cancellable { }

public typealias Progress = (Double)->()
public typealias OperationHandler = (Cancellable)->()
public typealias Completion = (Any?, Error?)->()

@objcMembers
@objc(ATOperationHelper)
open class OperationHelper: StaticSetupObject {

    private class OperationToken: Hashable {
        var id: String
        var completion: Completion
        var operation: Cancellable?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func ==(lhs: OperationToken, rhs: OperationToken) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        init(id: String, completion: @escaping Completion) {
            self.id = id
            self.completion = completion
        }
    }
    
    ///required for using LoadingTypeTranslucent.
    open var processTranslucentError: ((UIView, Error, /*retry*/ (()->())?)->())!
    
    ///by default retry appears in all operations
    open var shouldSupplyRetry: ((Any?, Error)->Bool)?
    
    open var loadingViewType: LoadingView.Type = LoadingView.self
    private weak var loadingView: LoadingView?
    
    open var loadingBarViewType: LoadingBarView.Type = LoadingBarView.self
    private var loadingBarView: LoadingBarView?
    
    open var failedViewType: FailedView.Type = FailedView.self
    private var failedView: FailedView?
    
    open var failedBarViewType: AlertBarView.Type = AlertBarView.self
    private weak var failedBarView: AlertBarView?
    
    open weak var view: UIView?
    private var keyedOperations: [String:OperationToken] = [:]
    private var processing = Set<OperationToken>()
    private var loadingCounter = 0
    private var touchableLoadingCounter = 0
    
    public init(view: UIView) {
        self.view = view
        
        shouldSupplyRetry = { (_, error) in
            return (error as NSError).domain != "NetworkKit.com"
        }
        
        processTranslucentError = { (_, error, retry) in
            
            let cancelTitle = retry != nil ? "Cancel" : "OK"
            var otherActions: [(String, (()->())?)] = []
            if retry != nil {
                otherActions.append(("Retry", { retry?() }))
            }
            Alert.present(error.localizedDescription, cancel: cancelTitle, other: otherActions, on: UIViewController.topViewController)
        }
        super.init()
    }
    
    private func cancel(token: OperationToken) {
        processing.remove(token)
        token.operation?.cancel()
        token.completion(nil, NSError(domain: "OperationHelper", code: NSURLErrorCancelled, userInfo: nil))
    }
    
    // progress indicator becomes visible on first Progress block performing
    // 'key' is needed to cancel previous launched operation with the same key, you can pass nil if you don't need such functional
    @objc open func run(_ closure: @escaping (@escaping Completion, @escaping OperationHandler, @escaping Progress)->(), completion: Completion?, loading: LoadingType, key: String?) {
        
        assert(loading != .translucent || processTranslucentError != nil, "_processTranslucentError block must be set to use LoadingTypeTranslucent")
        
        increament(loading: loading)
        if let key = key {
            if let token = keyedOperations[key] {
                cancel(token: token)
            }
        }
        
        if loading == .fullscreen || loading == .translucent {
            failedView?.removeFromSuperview()
        }
        
        let token = OperationToken(id: UUID().uuidString,
                                     completion: { [weak self] (request, error) in
                                        if let wSelf = self {
                                            wSelf.decrement(loading: loading)
                                            
                                            if let key = key {
                                                wSelf.keyedOperations[key] = nil
                                            }
                                            
                                            if let error = error {
                                                var retry: (()->())?
                                                
                                                if wSelf.shouldSupplyRetry?(request, error) ?? true {
                                                    retry = { wSelf.run(closure, completion: completion, loading: loading, key: key) }
                                                }
                                                wSelf.process(error: error, retry: retry, loading: loading)
                                            }
                                            completion?(request, error)
                                        }
        })
        processing.insert(token)
        if let key = key {
            keyedOperations[key] = token
        }
        
        closure({ [weak self] (request, error) in
            if let wSelf = self {
                if wSelf.processing.contains(token) {
                    wSelf.processing.remove(token)
                    token.completion(request, error)
                }
            }
        }, { [weak self] (operation) in
            if let wSelf = self {
                if wSelf.processing.contains(token) {
                    token.operation = operation
                }
            }
        }, { [weak self] (progress) in
            if let wSelf = self {
                if wSelf.processing.contains(token) {
                    if loading == .fullscreen || loading == .translucent {
                        wSelf.loadingView?.progress = CGFloat(progress)
                    } else if loading == .touchable {
                        wSelf.loadingBarView?.progress = CGFloat(progress)
                    }
                }
            }
        })
    }
    
    open func run(_ closure: @escaping (@escaping Completion)->(Cancellable?), loading: LoadingType, key: String?) {
        run({ (completion, operation, _) in
            if let task = closure(completion) {
                operation(task)
            }
        }, completion: nil, loading: loading, key: key)
    }
    
    open func run(_ closure: @escaping (@escaping Completion)->(Cancellable?), loading: LoadingType) {
        run(closure, loading: loading, key: nil)
    }
    
    private func process(error: Error, retry: (()->())?, loading: LoadingType) {
        if (error as NSError).code == NSURLErrorCancelled {
            return
        }
        guard let view = view else { return }
        
        if loading == .translucent {
            processTranslucentError(view, error, retry)
        } else if loading == .fullscreen {
            failedView = self.failedViewType.present(in: view, text: error.localizedDescription, retry: retry)
        } else if loading == .touchable {
            if failedBarView?.message() ?? "" != error.localizedDescription {
                failedBarView = failedBarViewType.present(in: view, message: error.localizedDescription)
            }
        }
    }
    
    private func increament(loading: LoadingType) {
        guard let view = view else { return }
        
        if loading == .translucent || loading == .fullscreen {
            if loadingCounter == 0 {
                loadingView = loadingViewType.present(in: view, animated: (loading == .translucent) && view.window != nil && failedView == nil)
            }
            if loading == .fullscreen && loadingView?.opaqueStyle == false {
                loadingView?.opaqueStyle = true
            }
            loadingCounter += 1
        } else if loading == .touchable {
            if touchableLoadingCounter == 0 {
                loadingBarView = loadingBarViewType.present(in: view, animated: true)
            }
            touchableLoadingCounter += 1
        }
    }
    
    private func decrement(loading: LoadingType) {
        if loading == .translucent || loading == .fullscreen {
            loadingCounter -= 1
            if loadingCounter == 0 {
                loadingView?.hide(true)
            }
        } else if loading == .touchable {
            touchableLoadingCounter -= 1
            if touchableLoadingCounter == 0 {
                loadingBarView?.hide(true)
            }
        }
    }
    
    @objc open func cancelOperations() {
        processing.forEach {
            self.cancel(token: $0)
        }
    }
    
    deinit {
        cancelOperations()
    }
}
