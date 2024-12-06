import Foundation
import Security

enum KeychainManager {
	static let tokenKey = "com.lazyai.accessToken"
	
	static func save(token: String) throws {
		let data = token.data(using: .utf8)!
		
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tokenKey,
			kSecValueData as String: data
		]
		
		// 先删除已存在的
		SecItemDelete(query as CFDictionary)
		
		let status = SecItemAdd(query as CFDictionary, nil)
		guard status == errSecSuccess else {
			throw KeychainError.saveFailed
		}
	}
	
	static func getToken() throws -> String? {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tokenKey,
			kSecReturnData as String: true
		]
		
		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		
		guard status == errSecSuccess,
			  let data = result as? Data,
			  let token = String(data: data, encoding: .utf8) else {
			return nil
		}
		
		return token
	}
	
	static func deleteToken() throws {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tokenKey
		]
		
		let status = SecItemDelete(query as CFDictionary)
		guard status == errSecSuccess || status == errSecItemNotFound else {
			throw KeychainError.deleteFailed
		}
	}
}

enum KeychainError: Error {
	case saveFailed
	case deleteFailed
	case notFound
}

