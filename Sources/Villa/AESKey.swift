//
//  AESKey.swift
//  CYaml
//
//  Created by Jack Maloney on 6/29/19.
//

import Foundation
import CryptoSwift

public struct AESKey: Codable {
    /// Name of this key
    public var name: String
    /// Variant of AES this key is for [128, 192, 256]
    public var variant: AES.Variant
    /// Salt used in PBKDF2
    public var salt: [UInt8]
    /// First half of PBKDF2 key used to verify password correctness and NOTHING ELSE
    public var validate: [UInt8]
    /// IV used to encrypt the primary key with the second half of the PBKDF2 key
    public var nonce: [UInt8]
    /// Encrypted bytes of the primary key
    public var bytes: [UInt8]
    /// If the key is decrypted it is stored here, NEVER ON DISK
    public var decrypted: [UInt8]? = nil

    /// 32 Bytes. Size of SHA256 used in PBKDF2.
    private static var saltLen = 32
    
    /// 16 byte IV.
    private static var nonceLen = 16
    
    enum CodingKeys: CodingKey {
        case name
        case salt
        case nonce
        case validate
        case key
    }
    
    /// Used only in generate() method, which is the public interface for creating a new key.
    private init(name: String, variant: AES.Variant, salt: [UInt8], validate: [UInt8], nonce: [UInt8], encrypted: [UInt8]) {
        self.name = name
        self.variant = variant
        self.salt = salt
        self.validate = validate
        self.nonce = nonce
        self.bytes = encrypted
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try values.decode(String.self, forKey: .name)
        self.salt = Array<UInt8>(hex: try values.decode(String.self, forKey: .salt))
        self.nonce = Array<UInt8>(hex: try values.decode(String.self, forKey: .nonce))
        self.bytes = Array<UInt8>(hex: try values.decode(String.self, forKey: .key))
        self.validate = Array<UInt8>(hex: try values.decode(String.self, forKey: .validate))
        
        guard self.bytes.count == self.validate.count,
            self.nonce.count == AESKey.nonceLen,
            self.salt.count == AESKey.saltLen else { fatalError() }
        
        switch self.bytes.count {
        case AES.Variant.aes128.keySize: self.variant = .aes128
        case AES.Variant.aes192.keySize: self.variant = .aes192
        case AES.Variant.aes256.keySize: self.variant = .aes256
        default: fatalError()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        guard self.bytes.count == self.variant.keySize,
            self.validate.count == self.variant.keySize else {
                print(self.validate)
                print(self.bytes)
                print(self.variant.keySize)
                fatalError()
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.salt.toHexString(), forKey: .salt)
        try container.encode(self.nonce.toHexString(), forKey: .nonce)
        try container.encode(self.validate.toHexString(), forKey: .validate)
        try container.encode(self.bytes.toHexString(), forKey: .key)
    }
    
    /// Generate a new AES Key.
    internal static func generate(name: String, variant: AES.Variant, password: String) throws -> AESKey {
        // https://security.stackexchange.com/a/38854
        let salt = try Array<UInt8>(withRandomBytes: AESKey.saltLen)
        
        let (encrypt, validate) = try AESKey.pbkdf2ToKeys(password: password, salt: salt, variant: variant)
        
        let nonce = try Array<UInt8>(withRandomBytes: AESKey.nonceLen)  // iv
        let key = try Array<UInt8>(withRandomBytes: variant.keySize)    // k1
        
        // https://security.stackexchange.com/a/52674
        let aes = try AES(key: encrypt, blockMode: CTR(iv: nonce), padding: .noPadding)
        let encryptedKey = try aes.encrypt(key)
        
        return AESKey(name: name, variant: variant, salt: salt, validate: validate, nonce: nonce, encrypted: encryptedKey)
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
    
    public mutating func attemptDecryption(withPassword password: String) throws -> Bool {
        // https://security.stackexchange.com/a/38854
        let (decrypt, validate) = try AESKey.pbkdf2ToKeys(password: password, salt: self.salt, variant: self.variant)
        
        guard validate == self.validate else {
            // Passwords don't match.
            return false
        }
        
        // Passwords match, decrypt.
        let aes = try AES(key: decrypt, blockMode: CTR(iv: nonce), padding: .pkcs7)
        self.decrypted = try aes.decrypt(self.bytes)
        
        return true
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
