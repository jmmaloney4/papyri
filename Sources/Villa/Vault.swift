// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PathKit
import Yams
import CryptoSwift

public class Vault: Codable {
    public var name: String
    public private(set) var path: Path
    public private(set) var key: AESKey?
    // TODO: Make this a binary tree or something
    var hashIndex: [HashIndexFile.Entry]? = nil
    
    var encrypted: Bool { return self.key != nil }
    
    var vaultFilePath: Path { return (self.path + Villa.Paths.vaultFile).normalize() }
    var keyFilePath: Path { return (self.path + Villa.Paths.keyFile).normalize() }
    var hashIndexPath: Path { return (self.path + Villa.Paths.hashIndexFile).normalize() }
    
    init(atPath path: Path) throws {
        self.path = path
        if !self.path.exists { throw VaultError.vaultDoesNotExist(self.path) }
        let vaultFilePath = (self.path + Villa.Paths.vaultFile).normalize()
        let keyFilePath = (self.path + Villa.Paths.keyFile).normalize()
        
        let decoder = YAMLDecoder()
        
        // Parse vault.yml
        if !vaultFilePath.exists { throw VaultError.vaultFileDoesNotExist(vaultFilePath) }
        let vaultFile = try decoder.decode(VaultFile.self, from: vaultFilePath.read())
        self.name = vaultFile.name
        
        if vaultFile.encrypt {
            // Load key from key.json
            if !keyFilePath.exists { throw VaultError.keyFileDoesNotExist(keyFilePath) }
            self.key = try decoder.decode(AESKey.self, from: keyFilePath.read())
        } else {
            self.key = nil
        }
    }
    
    private init(name: String, path: Path, key: AESKey) {
        self.name = name
        self.path = path
        self.key = key
        self.hashIndex = []
    }
    
    public static func createVault(atPath path: Path,
                                   withName name: String,
                                   andPassword password: String,
                                   variant: AES.Variant = .aes128) throws -> Vault {
        try path.mkpath()
        
        let key = try AESKey.generate(name: name, variant: variant, password: password)
        
        let rv =  Vault(name: name, path: path, key: key)
        try rv.writeVaultFile()
        try rv.writeKeyFile()
        try rv.writeHashIndex()
        return rv
    }
    
    private func writeVaultFile() throws {
        let vaultFile = VaultFile(name: self.name, encrypt: self.key != nil)
        let encoder = YAMLEncoder()
        let data = try encoder.encode(vaultFile)
        try self.vaultFilePath.write(data)
    }
    
    private func writeKeyFile() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self.key)
        try self.keyFilePath.write(data)
    }
    
    private func loadHashIndex() throws {
        if !self.encrypted { throw VaultError.encryptionNotEnabled }
        
        if !self.hashIndexPath.exists {
            throw VaultError.hashIndexFileDoesNotExist(self.hashIndexPath)
        }
        
        let decoder = JSONDecoder()
        let hashFile = try decoder.decode(HashIndexFile.self, from: self.hashIndexPath.read())
        self.hashIndex = hashFile.entries
    }
    
    private func writeHashIndex() throws {
        if !self.encrypted { throw VaultError.encryptionNotEnabled }

        guard self.hashIndex != nil else { throw VaultError.hashIndexNotLoaded }
        
        let encoder = JSONEncoder()
        let hashFile = HashIndexFile(entries: self.hashIndex!)
        try self.hashIndexPath.write(encoder.encode(hashFile))
    }
    
    func saveData(_ input: Data) throws -> Hash {
        if self.encrypted && self.hashIndex == nil {
            throw VaultError.hashIndexNotLoaded
        }
        
        var data: Data
        var hash: Hash
        let plaintext = Constants.UnencryptedBlobHeader + input
        if self.encrypted {
            // Encrypt
            let (encrypted, iv) = try self.key!.encrpytData(input)
            let ciphertext = Constants.EncryptedBlobHeader + iv + encrypted
            
            let entry = HashIndexFile.Entry(pt: Hash(plaintext), ct: Hash(ciphertext))
            self.hashIndex!.append(entry)
            
            data = ciphertext
            hash = entry.ct
        } else {
            data = plaintext
            hash = Hash(plaintext)
        }
        
        try self.writeDataAtHashPath(data, hash)
        return hash
    }
    
    private func writeDataAtHashPath(_ data: Data, _ hash: Hash) throws {
        let path = getDBPathForHash(hash)
        try path.parent().mkpath()
        try path.write(data)
    }
    
    func getDBPathForHash(_ hash: Hash, directory: Bool = false) -> Path {
        let hex = hash.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        let part2 = hex.suffix(from: splitIndex)
        
        var path: Path
        if directory {
            path = Path("\(part1)/")
        } else {
            path = Path("\(part1)/\(part2)")
        }
        
        return self.path + Villa.Paths.dbDir + path
    }
    
    public func close() throws {
        try self.writeVaultFile()
        try self.writeKeyFile()
        try self.writeHashIndex()
    }
    
    deinit {
        try! self.close()
    }
}

extension Vault {
    private struct Constants {
        static let EncryptedBlobHeader = Data("blob#".utf8)
        static let UnencryptedBlobHeader = Data("blob".utf8)
    }
    
    struct VaultFile: Codable {
        var name: String
        var encrypt: Bool
    }
    
    struct HashIndexFile: Codable {
        struct Entry: Codable {
            var pt: Hash // Plaintext Hash
            var ct: Hash // Cyphertext Hash
        }
        
        var entries: [Entry]
    }
    
    enum VaultError: Error {
        case vaultDoesNotExist(Path)
        case vaultFileDoesNotExist(Path)
        case keyFileDoesNotExist(Path)
        case hashIndexFileDoesNotExist(Path)
        
        case hashIndexNotLoaded
        case encryptionNotEnabled
    }

    
}
