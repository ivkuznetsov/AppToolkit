//
//  DispatchQueue+Detection.swift
//

import Foundation

extension DispatchQueue {

    private struct QueueReference { weak var queue: DispatchQueue? }

    private static let key: DispatchSpecificKey<QueueReference> = {
        let key = DispatchSpecificKey<QueueReference>()
        setupSystemQueuesDetection(key: key)
        return key
    }()

    private static func _registerDetection(of queues: [DispatchQueue], key: DispatchSpecificKey<QueueReference>) {
        queues.forEach { $0.setSpecific(key: key, value: QueueReference(queue: $0)) }
    }

    private static func setupSystemQueuesDetection(key: DispatchSpecificKey<QueueReference>) {
        let queues: [DispatchQueue] = [
                                        .main,
                                        .global(qos: .background),
                                        .global(qos: .default),
                                        .global(qos: .unspecified),
                                        .global(qos: .userInitiated),
                                        .global(qos: .userInteractive),
                                        .global(qos: .utility)
                                    ]
        _registerDetection(of: queues, key: key)
    }
}

public extension DispatchQueue {
    
    ///Register qeue to be detected in the code.
    static func registerDetection(of queue: DispatchQueue) {
        _registerDetection(of: [queue], key: key)
    }

    ///Obtain current queue lable. This works only on queues created with makeRegistered() method.
    static var currentQueueLabel: String? { current?.label }
    
    ///Obtain current queue. This works only on queues created with makeRegistered() method.
    static var current: DispatchQueue? { getSpecific(key: key)?.queue }
    
    ///Perform sync operation on serial queue. If we are currently in this queue the code won't be deadlocked. This works only on queues created with makeRegistered() method
    func syncSafe(_ block: ()->()) {
        if DispatchQueue.current == self {
            block()
        } else {
            sync(execute: block)
        }
    }
    
    ///Perform sync operation on serial queue with value return. If we are currently in this queue the code won't be deadlocked. This works only on queues created with makeRegistered() method
    @discardableResult func syncSafe<T>(_ block: ()->T) -> T {
        if DispatchQueue.current == self {
            return block()
        } else {
            return sync(execute: block)
        }
    }
    
    ///Perform task asynchronous using global queue with default quality of service.
    static func asyncGlobal(_ block: @escaping ()->()) {
        DispatchQueue.global(qos: .default).async(execute: block)
    }
    
    ///Make new serial queue with ability for the code to detect when it's performed on this queue
    static func makeRegistered(_ label: String) -> DispatchQueue {
        let queue = DispatchQueue(label: label)
        DispatchQueue.registerDetection(of: queue)
        return queue
    }
}
