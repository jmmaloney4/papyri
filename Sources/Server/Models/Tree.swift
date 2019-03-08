//
//  Tree.swift
//  App
//
//  Created by Jack Maloney on 2/21/19.
//

import Foundation
import FluentSQLite
import Vapor

struct Tree: SQLiteModel, Migration, Parameter {
    var id: Int?
    
    var files: [File]
    var subtrees: [Tree]
}
