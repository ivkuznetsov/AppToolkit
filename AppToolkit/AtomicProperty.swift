//
//  AtomicProperty.swift
//

import Foundation

///Wrapper for properties to make them atomic for read/write operations. This is needed to prevent memory errors during access to the value from different threads at the same time.
@propertyWrapper
public struct Atomic<T> {
    private var value: T
    private let lock = NSLock()

    ///Initializer
    public init(wrappedValue value: T) {
        self.value = value
    }

    ///Obtain stored value safely using NSLock underthehood.
    public var wrappedValue: T {
      get { getValue() }
      set { setValue(newValue: newValue) }
    }

    ///Thread safe getting value
    func getValue() -> T {
        lock.lock()
        defer { lock.unlock() }

        return value
    }

    ///Thread safe setting value
    mutating func setValue(newValue: T) {
        lock.lock()
        defer { lock.unlock() }

        value = newValue
    }
}
