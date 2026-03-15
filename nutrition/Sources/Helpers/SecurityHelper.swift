import Foundation
import CryptoKit

class SecurityHelper {
    static let shared = SecurityHelper()
    
    // In a real app, use Keychain to store the key securely.
    // For this prototype, we use a static key to ensure data persistence across app restarts.
    // WARNING: Do NOT use this in production.
    private let key = SymmetricKey(data: SHA256.hash(data: "MySecretAppKeyForDemoOnly".data(using: .utf8)!))
    
    func encrypt(_ data: Data) -> Data? {
        // Mock encryption for demo (using AES.GCM)
        // In production, manage the key securely
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    func decrypt(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)
            return decrypted
        } catch {
            print("Decryption error: \(error)")
            return nil
        }
    }
    
    func desensitizePhoneNumber(_ phone: String) -> String {
        guard phone.count >= 7 else { return phone }
        let start = phone.index(phone.startIndex, offsetBy: 3)
        let end = phone.index(phone.endIndex, offsetBy: -4)
        return phone.replacingCharacters(in: start..<end, with: "****")
    }
}
