// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PathKit

public struct File: Codable, Object {    
    public var id: Hash
    public var name: String
    var dateAdded: Date
    var fileType: FileType
    var branches: [Branch]
    var tags: [Tag]
    
    init(name: String) throws {
        self.name = name
        self.dateAdded = Date()
        self.fileType = FileType.forExtension(Path(name).extension ?? "") ?? .plain
        self.branches = []
        self.tags = []
        
        let rand = try [UInt8](withRandomBytes: 32)
        var hashData = Data()
        hashData.append(contentsOf: rand)
        hashData.append(self.name.data(using: .utf8)!)
        self.id = Hash(withData: hashData)
    }
    
    mutating func addBranch(_ branch: Branch) {
        self.branches.append(branch)
    }
}

struct Branch: Object, Codable, Hashable {
    var id: Hash
    var name: String
    var file: Hash
    var head: Hash
    
    init(name: String, file: Hash, commit: Commit) {
        self.name = name
        self.file = file
        self.head = commit.id
        
        var data = Data()
        data.append(self.name.data(using: .utf8)!)
        data.append(contentsOf: self.file.bytes)
        self.id = Hash(withData: data)
    }
}

struct Tag: Object, Codable, Hashable {
    var id: Hash
    var name: String
    var commit: Hash
}

struct Commit: Object, Codable, Hashable {
    var id: Hash
    var message: String
    
    struct File: Codable, Hashable {
        var file: Hash // Index
        var parent: Hash? // Parent Commit, in context of this file. nil if root commit.
        var blob: Hash // Blob committed in this commit, for this file.
    }
    
    var files: [File] = []
    
    private enum CodingKeys: String, CodingKey {
        case message
        case files
    }
    
    init(message: String) {
        self.message = message
    }
    
    mutating func addFile(file: Hash, parent: Hash?, blob: Hash) {
        files.append(File(file: file, parent: parent, blob: blob))
    }
}
