// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import PathKit

public class Villa {
    private var config: Config
    private var index: [Hash] = []
    
    public static var shared: Villa = try! Villa()
    
    init() throws {
        let decoder = JSONDecoder()
        self.config = try decoder.decode(Config.self, from: try! Paths.config.read())
        self.config.database = self.config.database.normalize().absolute()
        
        if !self.config.indexPath.exists {
            try self.config.indexPath.write("")
        } else {
            let indexFile: String = try self.config.indexPath.read()
            for line in indexFile.split(separator: "\n") {
                self.index.append(try Hash(withHex: String(line)))
            }
        }
    }
    
    func writeIndex() throws {
        try index.map({ $0.hex })
            .joined(separator: "\n")
            .write(to: URL(fileURLWithPath: config.indexPath.string), atomically: true, encoding: .utf8)
    }
    
    public func newFile(data: Data, name: String) throws -> File {
        var file = try File(name: name)
        self.index.append(file.id)
        try self.writeIndex()
        
        let blob = try Blob(withData: data)
        try blob.write(toDB: self.config.database)
        
        let commit = Commit(message: "Initial Commit")
        let branch = Branch(name: "master", file: file.id, commit: commit)
        file.addBranch(branch)
        
        return file
    }
    
    public func allFiles() throws -> [File] {
        var rv: [File] = []
        for hash in index {
            rv.append(try File(withId: hash, atDB: config.database))
        }
        return rv
    }
}

fileprivate extension Villa {
    struct Paths {
        public static let config = Path.home + Path(".villa/config")
        public static let index = Path("index")
    }
    
    struct Config: Codable {
        var database: Path
        
        var indexPath: Path {
            return (self.database + Paths.index).normalize()
        }
    }
}

extension Path {
    var url: URL {
        return URL(fileURLWithPath: self.string)
    }
}
