// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PathKit

protocol Object: Codable {
    var id: Hash { get }
    
    init(withId id: Hash, atDB dbPath: Path) throws
    func write(toDB dbPath: Path) throws
}

extension Object {
    func write(toDB dbPath: Path) throws {
        let data = try JSONEncoder().encode(self)
        let path = dbPath + self.id.dbPath()
        try path.write(data)
    }
    
    init(withId id: Hash, atDB dbPath: Path) throws {
        let path = dbPath + id.dbPath()
        self = try JSONDecoder().decode(Self.self, from: try path.read())
        guard self.id == id else {
            fatalError("Given id and saved id do not agree.")
        }
    }
    
    func createDBDir(atDB dbPath: Path) throws {
        let prefix = dbPath + self.id.dbPrefix()
        
        if !prefix.exists {
            try prefix.mkpath()
        } else if !prefix.isDirectory {
            try prefix.delete()
            try prefix.mkpath()
        }
    }
}

protocol ImmutableObject: Object {
    
}

extension ImmutableObject {
    
}

protocol MutableObject: Object {
    
}

// Object with cryptographic hash guarantee, used for storage of actual file data and commits.
// Data is immutable because of hashing.
struct Blob: ImmutableObject, Codable {
    var id: Hash
    var data: Data
    var salt: [UInt8]
    
    private static let RandomBytesSaltCount = 8
    
    init(withData data: Data) throws {
        self.data = data
        
        self.salt = try [UInt8](withRandomBytes: Blob.RandomBytesSaltCount)
        var hashData = Data()
        hashData.append(contentsOf: self.salt)
        hashData.append(self.data)
        self.id = Hash(withData: hashData)
    }
    
    init(withId id: Hash, atDB dbPath: Path) throws {
        self.id = id
        
        let path = dbPath + self.id.dbPath()
        let data = try path.read()
        self.salt = data.prefix(upTo: Blob.RandomBytesSaltCount).bytes
        self.data = data.suffix(from: Blob.RandomBytesSaltCount)
        
        let sha = Hash(withData: data)
        guard self.id == sha else {
            fatalError("Corrupted file, expected \(self.id), got \(sha)")
        }
    }
    
    func write(toDB dbPath: Path) throws {
        let path = dbPath + self.id.dbPath()
        print(path)
        var data = Data()
        data.append(contentsOf: self.salt)
        data.append(self.data)
        
        guard self.id == Hash(withData: data) else {
            fatalError("Refusing to write incorrect data, expected \(self.id), got \(Hash(withData: data))")
        }
        
        try self.createDBDir(atDB: dbPath)
        
        try path.write(data)
    }
}
/*
// Other objects, IndexFile, Branch, Tag, etc
class MutableObject: Object, Codable, Equatable {
    var id: SHA256
    var data: Data
    
    required init(withData data: Data, id: SHA256) throws {
        self.id = id
        self.data = data
    }
    
    required init(withId id: SHA256, atDB dbPath: Path) throws {
        self.id = id
        
        let path = dbPath + self.id.dbPath()
        self.data = try path.read()
    }
    
    func write(toDB dbPath: Path) throws {
        let path = dbPath + self.id.dbPath()
        try path.write(self.data)
    }
    
    static func == (lhs: MutableObject, rhs: MutableObject) -> Bool {
        return lhs.id == rhs.id
    }
}
*/

fileprivate extension Hash {
    func dbPath() -> Path {
        let hex = self.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        let part2 = hex.suffix(from: splitIndex)
        return Path("\(part1)/\(part2)")
    }
    
    func dbPrefix() -> Path {
        let hex = self.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        return Path(String(part1))
    }
}

