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
    public private(set) var key: AESKey
    // TODO: Make this a binary tree or something
    var hashIndex: [HashIndexFile.Entry]? = nil
    
    var vaultFilePath: Path { return (self.path + Villa.Paths.vaultFile).normalize() }
    var keyFilePath: Path { return (self.path + Villa.Paths.keyFile).normalize() }
    var hashIndexPath: Path { return (self.path + Villa.Paths.hashIndexFile).normalize() }
    
    init(atPath path: Path) throws {
        self.path = path
        let vaultFilePath = (self.path + Villa.Paths.vaultFile).normalize()
        let keyFilePath = (self.path + Villa.Paths.keyFile).normalize()
        
        let decoder = YAMLDecoder()
        
        // Parse vault.yml
        if !vaultFilePath.exists { throw VaultError.vaultFileDoesNotExist(vaultFilePath) }
        let vaultFile = try decoder.decode(VaultFile.self, from: vaultFilePath.read())
        self.name = vaultFile.name
        
        if !keyFilePath.exists { throw VaultError.keyFileDoesNotExist(keyFilePath) }
        self.key = try decoder.decode(AESKey.self, from: keyFilePath.read())
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
        let vaultFile = VaultFile(name: self.name)
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
        if !self.hashIndexPath.exists {
            throw VaultError.hashIndexFileDoesNotExist(self.hashIndexPath)
        }
        
        let decoder = JSONDecoder()
        let hashFile = try decoder.decode(HashIndexFile.self, from: self.hashIndexPath.read())
        self.hashIndex = hashFile.entries
    }
    
    private func writeHashIndex() throws {
        guard self.hashIndex != nil else {
            throw VaultError.hashIndexNotLoaded
        }
        
        let encoder = JSONEncoder()
        let hashFile = HashIndexFile(entries: self.hashIndex!)
        try self.hashIndexPath.write(encoder.encode(hashFile))
    }
}

extension Vault {
    struct VaultFile: Codable {
        var name: String
    }
    
    struct HashIndexFile: Codable {
        struct Entry: Codable {
            var pt: Hash // Plaintext Hash
            var ct: Hash // Cyphertext Hash
        }
        
        var entries: [Entry]
    }
    
    enum VaultError: Error {
        case vaultFileDoesNotExist(Path)
        case keyFileDoesNotExist(Path)
        case hashIndexFileDoesNotExist(Path)
        
        case hashIndexNotLoaded
    }
}
