// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PathKit

struct File: Codable, Object {    
    var id: SHA256
    var name: String
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
        self.id = SHA256(withData: hashData)
    }
    
    mutating func addBranch(_ branch: Branch) {
        self.branches.append(branch)
    }
}

struct Branch: Object, Codable, Hashable {
    var id: SHA256
    var name: String
    var file: SHA256
    var head: SHA256
    
    init(name: String, file: SHA256, commit: Commit) {
        self.name = name
        self.file = file
        self.head = commit.id
        
        var data = Data()
        data.append(self.name.data(using: .utf8)!)
        data.append(contentsOf: self.file.bytes)
        self.id = SHA256(withData: data)
    }
}

struct Tag: Object, Codable, Hashable {
    var id: SHA256
    var name: String
    var commit: SHA256
}

struct Commit: Codable, Hashable {
    var id: SHA256!
    var message: String
    
    struct File: Codable, Hashable {
        var file: SHA256 // Index
        var parent: SHA256? // Parent Commit, in context of this file. nil if root commit.
        var blob: SHA256 // Blob committed in this commit, for this file.
    }
    
    var files: [File] = []
    
    private enum CodingKeys: String, CodingKey {
        case message
        case files
    }
    
    init(message: String) {
        self.message = message
    }
    
    mutating func addFile(file: SHA256, parent: SHA256?, blob: SHA256) {
        files.append(File(file: file, parent: parent, blob: blob))
    }
}
