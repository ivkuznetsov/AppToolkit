//
//  Keychain.swift
//

import Foundation

public class Keychain {
	
    private static func addQuery(service: String, password: Data) -> CFDictionary {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: password
            ] as CFDictionary
    }

	private static func retrieveQuery(service: String) -> CFDictionary {
		return [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecReturnAttributes as String: true,
			kSecReturnData as String: true
			] as CFDictionary
	}

	private static func searchQuery(service: String) -> CFDictionary {
		return [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			] as CFDictionary
	}

    private static func updateQuery(password: Data) -> CFDictionary {
        return [
            kSecValueData as String: password,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ] as CFDictionary
    }

	static func update(service: String, value: String) -> OSStatus {
        return update(service: service, value: value.data(using: .utf8)!)
	}
    
    static func update(service: String, value: Data) -> OSStatus {
        var status = SecItemAdd(addQuery(service: service, password: value), nil)

        if status == errSecDuplicateItem {
            status = SecItemUpdate(searchQuery(service: service), updateQuery(password: value))
        }

        guard status == errSecSuccess else {
            return status
        }

        return errSecSuccess
    }

	static func retrieve(service: String) -> (String?, OSStatus) {
        let result = retrieveData(service: service)
        
		guard
            let data = result.0,
            let key = String(data: data, encoding: .utf8)
			else {
				return (nil, errSecItemNotFound)
		}
		return (key, errSecSuccess)
	}
    
    static func retrieveData(service: String) -> (Data?, OSStatus) {
        var item: CFTypeRef?

        let status = SecItemCopyMatching(retrieveQuery(service: service), &item)
        guard status == errSecSuccess else {
            return (nil, status)
        }

        guard
            let existingItem = item as? [String : Any],
            let passwordData = existingItem[kSecValueData as String] as? Data
            else {
                return (nil, errSecItemNotFound)
        }

        return (passwordData, errSecSuccess)
    }

    public static func delete(service: String) -> OSStatus {
		return SecItemDelete(searchQuery(service: service))
	}
    
    public static func set(data: Data?, service: String) {
        if let data = data {
            _ = Keychain.update(service: service, value: data)
        } else {
            _ = Keychain.delete(service: service)
        }
    }
    
    public static func set(string: String?, service: String) {
        set(data: string?.data(using: .utf8), service: service)
    }
    
    public static func get(service: String) -> Data? {
        return retrieveData(service: service).0
    }
    
    public static func getString(service: String) -> String? {
        if let data = retrieveData(service: service).0 {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
