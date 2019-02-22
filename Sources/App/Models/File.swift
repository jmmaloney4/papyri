//
//  File.swift
//  App
//
//  Created by Jack Maloney on 2/21/19.
//

import Foundation
import FluentSQLite
import Vapor

struct File: SQLiteModel, Migration, Content, Parameter {
    var id: Int?
    var hash: SHA256
}

struct Version: SQLiteModel, Migration, Content, Parameter {
    var id: Int?
    var blob: Blob.ID
    var previous: Version.ID?
}
