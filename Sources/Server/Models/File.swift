//
//  File.swift
//  App
//
//  Created by Jack Maloney on 2/21/19.
//

import Foundation
import FluentSQLite
import Vapor
import Content

struct File: SQLiteModel, Migration, Parameter {
    var id: Int?
    var hash: SHA256
    var latest: Version.ID
}

struct Version: SQLiteModel, Migration, Parameter {
    var id: Int?
    var name: String
    var blob: Blob.ID
    var previous: Version.ID?
    var date: Date
    
    static func createWith(blob: Blob, name: String, on db: DatabaseConnectable) -> Future<Version> {
        return Version(id: nil, name: name, blob: blob.id!, previous: nil, date: Date())
            .save(on: db)
    }
    
    func createSubsequentVersion(blob: Blob, name: String? = nil, on db: DatabaseConnectable) -> Future<Version> {
        return Version(id: nil, name: name ?? self.name, blob: blob.id!, previous: self.id!, date: Date())
            .save(on: db)
    }
}

struct CodableDateWrapper: Codable {
    var value: Date
    
}
