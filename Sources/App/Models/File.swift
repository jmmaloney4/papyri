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
}
