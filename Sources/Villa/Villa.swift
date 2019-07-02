// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PathKit
import Yams
import CryptoSwift

public class Villa {
    private var config: Config
    private var index: [Hash] = []
    public var keys: [AESKey] = []
    public var vaults: [Vault] {
        didSet { try! writeConfigFile() }
    }
    
    public static var shared: Villa = try! Villa()
    
    init() throws {
        self.config = try Config.load()
        
        self.vaults = []
        for vault in config.vaults {
            if self.vaults.contains(where: { $0.path == vault }) {
                continue;
            }
            self.vaults.append(try Vault(atPath: vault))
        }
    }
    
    private func writeConfigFile() throws {
        self.config.vaults = self.vaults.map({ $0.path.abbreviate() })
        let encoder = YAMLEncoder()
        let data = try encoder.encode(self.config)
        try Paths.config.write(data)
    }
    
    func addFile(_ data: Data, toVaults vaults: [Vault]) throws {
        for vault in vaults {
            let blob = try vault.saveData(data)
            
        }
    }
}

internal extension Villa {
    struct Paths {
        public static let config = Path("~/.villa/config.yml").normalize()
        public static let index = Path("index")
        public static let keyFile = Path("key.json")
        public static let vaultFile = Path("vault.yml")
        public static let hashIndexFile = Path("hash_index.json")
        public static let dbDir = Path("db/")
    }
    
    struct KeysFile: Codable {
        var keys: [AESKey]
    }
    
    struct Config: Codable {
        var vaults: [Path]
        
        /// Where the file index file is stored
        // var indexPath: Path { return (self.database + Paths.index).normalize() }
        
        /// Where the encryption keys are stored
        // var keysFilePath: Path { return (self.database + Paths.keysFile).normalize() }
        
        static func load() throws -> Config {
            let ymlDecoder = YAMLDecoder()
            var config = try ymlDecoder.decode(Config.self, from: try Paths.config.read())
            config.vaults = config.vaults.map({ $0.normalize() })
            return config
        }
    }
    
    struct Branch {
        var file: Hash
        var name: String
        var head: Hash
    }
    
    struct FileMetadata {
        var file: Hash? // nil if root commit
        var filename: String
        var branches: [Branch]
    }
    
    struct Commit {
        var file: Hash
        var blob: Hash
        var message: String
        
    }
}

