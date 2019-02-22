//
//  Tree.swift
//  App
//
//  Created by Jack Maloney on 2/21/19.
//

import Foundation
import FluentSQLite

struct Tree: SQLiteModel {
    var id: Int?
    
    var files: [File]
    var subtrees: [Tree]
}
