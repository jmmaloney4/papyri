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
    
    public static var shared: Villa = try! Villa()
    
    init() throws {
        self.config = try Config.load()
        
        // Decode keys.json file
        if config.keysFilePath.exists {
            let jsonDecoder = JSONDecoder()
            self.keys = try jsonDecoder.decode([AESKey].self, from: try config.keysFilePath.read())
        } else {
            self.keys = []
        }
        
        // Decode index file
        if !self.config.indexPath.exists {
            try self.config.indexPath.write("")
        } else {
            let indexFile: String = try self.config.indexPath.read()
            for line in indexFile.split(separator: "\n") {
                self.index.append(try Hash(withHex: String(line)))
            }
        }
    }
    
    func updateKeysFile() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self.keys)
        try self.config.keysFilePath.write(data)
    }
    
    public func generateNewKey(name: String, variant: AES.Variant = .aes128, password: String) throws -> AESKey {
        let key = try AESKey.generate(name: name, variant: variant, password: password)
        self.keys.append(key)
        try self.updateKeysFile()
        return key
    }
    
    // TODO: Refactor with KeyPaths?
    public func getKeyWithName(_ name: String) -> AESKey? {
        let matching = self.keys.filter({ $0.name == name })
        if matching.count > 1 { fatalError() }
        if matching.count == 1 { return matching[0] }
        else { return nil }
    }
    
    public func getKeyWithShortHash(_ hash: String) -> AESKey? {
        let matching = self.keys.filter({ $0.shortHash == hash })
        if matching.count > 1 { fatalError() }
        if matching.count == 1 { return matching[0] }
        else { return nil }
    }
    
    func writeIndex() throws {
        try index.map({ $0.hex })
            .joined(separator: "\n")
            .write(to: URL(fileURLWithPath: config.indexPath.string), atomically: true, encoding: .utf8)
    }

    func saveData(_ data: Data) throws  {
        
    }
}

fileprivate extension Villa {
    struct Paths {
        public static let config = Path.home + Path(".villa/config.yml")
        public static let index = Path("index")
        public static let keys = Path("keys.json")
    }
    
    struct Config: Codable {
        var database: Path
        
        /// Where the file index file is stored
        var indexPath: Path { return (self.database + Paths.index).normalize() }
        
        /// Where the encryption keys are stored
        var keysFilePath: Path { return (self.database + Paths.keys).normalize() }
        
        static func load() throws -> Config {
            let ymlDecoder = YAMLDecoder()
            var config = try ymlDecoder.decode(Config.self, from: try Paths.config.read())
            config.database = config.database.normalize().absolute()
            
            return config
        }
    }
}
