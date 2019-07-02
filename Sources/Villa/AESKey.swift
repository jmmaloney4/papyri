// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CryptoSwift

// Comparison of Cipher Modes - https://security.stackexchange.com/a/52674
// Password to Key Strategy - https://security.stackexchange.com/a/38854

public class AESKey: Codable {
    /// Name of this key
    public var name: String
    /// Variant of AES this key is for [128, 192, 256]
    public private(set) var variant: AES.Variant
    /// Salt used in PBKDF2
    public private(set) var salt: [UInt8]
    /// First half of PBKDF2 key used to verify password correctness and NOTHING ELSE
    public private(set) var validate: [UInt8]
    /// IV used to encrypt the primary key with the second half of the PBKDF2 key
    public private(set) var iv: [UInt8]
    /// Encrypted bytes of the primary key
    public private(set) var bytes: [UInt8]
    /// If the key is decrypted it is stored here, NEVER ON DISK
    public private(set) var decrypted: [UInt8]? = nil

    /// 32 Bytes. Size of SHA256 used in PBKDF2.
    private static var saltLength = 32
    
    /// 16 byte IV.
    private static var ivLength = 16
    
    enum CodingKeys: CodingKey {
        case name
        case salt
        case iv
        case validate
        case key
    }
    
    /// Used only in generate() method, which is the public interface for creating a new key.
    private init(name: String, variant: AES.Variant, salt: [UInt8], validate: [UInt8], iv: [UInt8], encrypted: [UInt8], decrypted: [UInt8]? = nil) {
        self.name = name
        self.variant = variant
        self.salt = salt
        self.validate = validate
        self.iv = iv
        self.bytes = encrypted
        self.decrypted = decrypted
    }
    
    private func validateInternalKeysizes() -> Bool {
        return  self.bytes.count == self.variant.keySize &&
                self.bytes.count == self.validate.count &&
                self.iv.count == AESKey.ivLength &&
                self.salt.count == AESKey.saltLength &&
                (self.decrypted == nil || self.decrypted!.count == self.bytes.count)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decode(String.self, forKey: .name)
        self.salt = Array<UInt8>(hex: try values.decode(String.self, forKey: .salt))
        self.iv = Array<UInt8>(hex: try values.decode(String.self, forKey: .iv))
        self.bytes = Array<UInt8>(hex: try values.decode(String.self, forKey: .key))
        self.validate = Array<UInt8>(hex: try values.decode(String.self, forKey: .validate))
        
        switch self.bytes.count {
        case AES.Variant.aes128.keySize: self.variant = .aes128
        case AES.Variant.aes192.keySize: self.variant = .aes192
        case AES.Variant.aes256.keySize: self.variant = .aes256
        default: throw AESKeyError.invalidKeysize(self.bytes.count)
        }
        
        guard self.validateInternalKeysizes() else { throw AESKeyError.invalidEncodingError }
    }
    
    public func encode(to encoder: Encoder) throws {
        guard self.validateInternalKeysizes() else {
                print(self.validate)
                print(self.bytes)
                print(self.variant.keySize)
                fatalError()
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.salt.toHexString(), forKey: .salt)
        try container.encode(self.iv.toHexString(), forKey: .iv)
        try container.encode(self.validate.toHexString(), forKey: .validate)
        try container.encode(self.bytes.toHexString(), forKey: .key)
    }
    
    /// Generate a new AES Key.
    internal static func generate(name: String, variant: AES.Variant, password: String) throws -> AESKey {
        // https://security.stackexchange.com/a/38854
        let salt = try Array<UInt8>(withRandomBytes: AESKey.saltLength)
        
        let (encrypt, validate) = try AESKey.pbkdf2ToKeys(password: password, salt: salt, variant: variant)
        
        let iv = try Array<UInt8>(withRandomBytes: AESKey.ivLength)  // iv
        let key = try Array<UInt8>(withRandomBytes: variant.keySize)    // k1
        
        // https://security.stackexchange.com/a/52674
        let aes = try AES(key: encrypt, blockMode: CTR(iv: iv), padding: .noPadding)
        let encryptedKey = try aes.encrypt(key)
        
        return AESKey(name: name, variant: variant, salt: salt, validate: validate, iv: iv, encrypted: encryptedKey, decrypted: key)
    }
    
    /// Use PBKDF2 to generate key to encrypt/decrypt primary key, and to verify password.
    /// **Returns (encrypt/decrypt, validate).**
    private static func pbkdf2ToKeys(password: String, salt: [UInt8], variant: AES.Variant) throws -> ([UInt8], [UInt8]) {
        // https://security.stackexchange.com/a/38854
        let pwbytes = Array<UInt8>(password.utf8)
        let key = try PKCS5.PBKDF2(password: pwbytes,
                                   salt: salt,
                                   iterations: 4096,
                                   keyLength: variant.keySize * 2, // Need two keys from this, so twice as long.
                                   variant: .sha256).calculate()

        let encrypt = Array<UInt8>(key[variant.keySize...])   // k2
        let validate = Array<UInt8>(key[..<variant.keySize])  // k3
        
        return (encrypt, validate)
    }
    
    internal func attemptDecryption(withPassword password: String) throws -> Bool {
        // https://security.stackexchange.com/a/38854
        let (decrypt, validate) = try AESKey.pbkdf2ToKeys(password: password, salt: self.salt, variant: self.variant)
        
        guard validate == self.validate else {
            // Passwords don't match.
            return false
        }
        
        // Passwords match, decrypt.
        let aes = try AES(key: decrypt, blockMode: CTR(iv: iv), padding: .noPadding)
        self.decrypted = try aes.decrypt(self.bytes)
        
        return true
    }
    
    func dumpDecryptedKey() throws {
        if self.decrypted == nil { return }
        let rand = try Array<UInt8>(withRandomBytes: self.decrypted!.count)
        self.decrypted!.enumerated().forEach { k, _ in self.decrypted![k] = rand[k] }
        self.decrypted!.forEach({ _ in self.decrypted!.removeFirst() })
        self.decrypted = nil
    }
    
    internal func encrpytData(_ input: Data) throws -> (Data, [UInt8]) {
        if self.decrypted == nil {
            throw AESKeyError.keyEncryptedError
        }
        
        let iv = try Array<UInt8>(withRandomBytes: AESKey.ivLength)
        let aes = try AES(key: self.decrypted!, blockMode: CTR(iv: iv), padding: .noPadding)
        let data = try Data(aes.encrypt(input.bytes))
        
        return (data, iv)
    }
    
    public var shortHash: String {
        return String(bytes.toHexString().prefix(7))
    }
}

public extension AES.Variant {
    var keySize: Int {
        switch self {
        case .aes128: return 16
        case .aes192: return 24
        case .aes256: return 32
        }
    }
    
    var name: String {
        switch self {
        case .aes128: return "AES-128"
        case .aes192: return "AES-192"
        case .aes256: return "AES-256"
        }
    }
}

public extension AESKey {
    enum AESKeyError: Error {
        case invalidKeysize(Int)
        case invalidEncodingError
        case keyEncryptedError
    }
}

struct EncryptedData {
    var ciphertext: Data
    var iv: [UInt8]
}
