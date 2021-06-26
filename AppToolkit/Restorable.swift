//
//  BaseRestorableViewController.swift
//  AppToolkit
//
//  Created by Ilya Kuznetsov on 6/6/21.
//  Copyright © 2021 Ilya Kuznetsov. All rights reserved.
//

import UIKit

public protocol Restorable {
    
    init()
    
    func processKeypaths(_ operation: RestorableOperation)
}

public struct RestorableOperation {
    
    public enum OperationType {
        case restore
        case store
    }
    
    public let operationType: OperationType
    let coder: NSCoder
}

public extension Restorable {
    
    func process<U: Codable>(_ keyPath: ReferenceWritableKeyPath<Self, U>, key: String? = nil, operation: RestorableOperation) {
        process(keyPath: keyPath, key: key ?? NSExpression(forKeyPath: keyPath).keyPath, operation: operation)
    }
    
    func process<U: Restorable>(_ keyPath: KeyPath<Self, U>, key: String? = nil, operation: RestorableOperation) {
        process(value: self[keyPath: keyPath], key: key ?? NSExpression(forKeyPath: keyPath).keyPath, operation: operation)
    }
    
    func store<U: Codable>(_ value: U, key: String, coder: NSCoder) {
        if let data = try? JSONEncoder().encode(value) {
            coder.encode(data, forKey: key)
        }
    }
    
    func restore<U: Codable>(type: U.Type, key: String, coder: NSCoder) -> U? {
        if let data = coder.decodeObject(forKey: key) as? Data, let result = try? JSONDecoder().decode(U.self, from: data) {
            return result
        }
        return nil
    }
    
    func process<U: Codable, V>(_ keyPath: ReferenceWritableKeyPath<Self, V>,
                                store: (V)->(U?),
                                restore: (U)->(V?),
                                key: String? = nil,
                                operation: RestorableOperation) {
        
        process(keyPath, store: store, restore: restore, key: NSExpression(forKeyPath: keyPath).keyPath, operation: operation)
    }
    
    func process<U: Codable, V>(_ keyPath: ReferenceWritableKeyPath<Self, [V]>,
                                store: (V)->(U?),
                                restore: (U)->(V?),
                                key: String? = nil,
                                operation: RestorableOperation) {
        
        let resultKey = key ?? NSExpression(forKeyPath: keyPath).keyPath
        if operation.operationType == .store {
            
            let values = self[keyPath: keyPath].compactMap { store($0) }
            self.store(values, key: resultKey, coder: operation.coder)
        } else if operation.operationType == .restore {
            
            if let value = self.restore(type: [U].self, key: resultKey, coder: operation.coder) {
                let result = value.compactMap { restore($0) }
                
                if result.count > 0 {
                    self[keyPath: keyPath] = result
                }
            }
        }
    }
    
    func process<U: Codable, V>(_ keyPath: ReferenceWritableKeyPath<Self, Set<V>>,
                                store: (V)->(U?),
                                restore: (U)->(V?),
                                key: String? = nil,
                                operation: RestorableOperation) {
        
        let resultKey = key ?? NSExpression(forKeyPath: keyPath).keyPath
        if operation.operationType == .store {
            
            let values = self[keyPath: keyPath].compactMap { store($0) }
            self.store(values, key: resultKey, coder: operation.coder)
        } else if operation.operationType == .restore {
            
            if let value = self.restore(type: [U].self, key: resultKey, coder: operation.coder) {
                let result = value.compactMap { restore($0) }
                
                if result.count > 0 {
                    self[keyPath: keyPath] = Set(result)
                }
            }
        }
    }
    
    func process<U: Codable>(_ keyPaths: [ReferenceWritableKeyPath<Self, U>], operation: RestorableOperation) {
        keyPaths.forEach { process(keyPath: $0, key: NSExpression(forKeyPath: $0).keyPath, operation: operation) }
    }
    
    func process<U: Codable>(_ keyPaths: [(ReferenceWritableKeyPath<Self, U>, String)], operation: RestorableOperation) {
        keyPaths.forEach { process(keyPath: $0.0, key: $0.1, operation: operation) }
    }
    
    private func process<U: Codable>(keyPath: ReferenceWritableKeyPath<Self, U>, key: String, operation: RestorableOperation) {
        if operation.operationType == .store {
            store(self[keyPath: keyPath], key: key, coder: operation.coder)
        } else if operation.operationType == .restore {
            if let value = restore(type: U.self, key: key, coder: operation.coder) {
                self[keyPath: keyPath] = value
            }
        }
    }
    
    func process<U: Codable, V>(_ keyPath: ReferenceWritableKeyPath<Self, V>,
                                store: (V)->(U?),
                                restore: (U)->(V?),
                                key: String,
                                operation: RestorableOperation) {
        
        if operation.operationType == .store {
            
            if let value = store(self[keyPath: keyPath]) {
                self.store(value, key: key, coder: operation.coder)
            }
        } else if operation.operationType == .restore {
            
            if let value = self.restore(type: U.self, key: key, coder: operation.coder) {
                if let restored = restore(value) {
                    self[keyPath: keyPath] = restored
                }
            }
        }
    }
    
    func process<U: Restorable>(_ keyPaths: [KeyPath<Self, U>], operation: RestorableOperation) {
        keyPaths.forEach { process(value: self[keyPath: $0], key: NSExpression(forKeyPath: $0).keyPath, operation: operation) }
    }
    
    func process<U: Restorable>(_ keyPaths: [(KeyPath<Self, U>, String)], operation: RestorableOperation) {
        keyPaths.forEach { process(value: self[keyPath: $0.0], key: $0.1, operation: operation) }
    }
    
    private func process(value: Restorable, key: String, operation: RestorableOperation) {
        if operation.operationType == .store {
        
            let archiver = NSKeyedArchiver()
            value.processKeypaths(RestorableOperation(operationType: .store, coder: archiver))
            operation.coder.encode(archiver.encodedData, forKey: key)
            
        } else if operation.operationType == .restore {
            
            if let data = operation.coder.decodeObject(forKey: key) as? Data {
                let archiver = NSKeyedUnarchiver(forReadingWith: data)
                value.processKeypaths(RestorableOperation(operationType: .restore, coder: archiver))
            }
        }
    }
    
    func process<U: Restorable>(_ keyPath: KeyPath<Self, [U]>, key: String? = nil, operation: RestorableOperation) {
        if let key = key {
            process([(keyPath, key)], operation: operation)
        } else {
            process([keyPath], operation: operation)
        }
    }
    
    func process<U: Restorable>(_ keyPaths: [KeyPath<Self, [U]>], operation: RestorableOperation) {
        keyPaths.forEach { process(value: self[keyPath: $0], key: NSExpression(forKeyPath: $0).keyPath, operation: operation) }
    }
    
    func process<U: Restorable>(_ keyPaths: [(KeyPath<Self, [U]>, String)], operation: RestorableOperation) {
        keyPaths.forEach { process(value: self[keyPath: $0.0], key: $0.1, operation: operation) }
    }
    
    private func process(value: [Restorable], key: String, operation: RestorableOperation) {
        if operation.operationType == .store {
        
            var dataArray: [Data] = []
            
            for restorable in value {
                let archiver = NSKeyedArchiver()
                restorable.processKeypaths(RestorableOperation(operationType: .store, coder: archiver))
                dataArray.append(archiver.encodedData)
            }
            let archiver = NSKeyedArchiver()
            archiver.encode(dataArray, forKey: "array")
            operation.coder.encode(archiver.encodedData, forKey: key)
            
        } else if operation.operationType == .restore {
            
            if let data = operation.coder.decodeObject(forKey: key) as? Data {
                let archiver = NSKeyedUnarchiver(forReadingWith: data)
                
                if let array = archiver.decodeObject(forKey: "array") as? [Data] {
                    array.enumerated().forEach { index, data in
                        let archiver = NSKeyedUnarchiver(forReadingWith: data)
                        
                        if value.count > index {
                            value[index].processKeypaths(RestorableOperation(operationType: .restore, coder: archiver))
                        }
                    }
                }
            }
        }
    }
}
