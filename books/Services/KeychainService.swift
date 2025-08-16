import Foundation
import KeychainAccess

class KeychainService {
    static let shared = KeychainService()
    private let keychain = Keychain(service: "com.oooefam.booksV3.keychain")

    private let apiKeyKey = "googleBooksAPIKey"

    func saveAPIKey(_ apiKey: String) throws {
        try keychain.set(apiKey, key: apiKeyKey)
    }

    func loadAPIKey() -> String? {
        return try? keychain.get(apiKeyKey)
    }

    func deleteAPIKey() throws {
        try keychain.remove(apiKeyKey)
    }

    #if DEBUG
    func loadAPIKeyForDebug() -> String {
        if let key = try? keychain.get(apiKeyKey) {
            return "Keychain Key: \(key)"
        } else {
            return "Keychain Key: Not Found"
        }
    }
    #endif
}
