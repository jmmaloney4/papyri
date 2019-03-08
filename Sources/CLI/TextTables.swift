//
//  TextTables.swift
//  Alamofire
//
//  Created by Jack Maloney on 3/8/19.
//

import Foundation
import Content
import SwiftyTextTable

extension FileInfoStruct: TextTableRepresentable {
    public static var columnHeaders: [String] {
        return ["hash", "size", "name"]
    }
    
    public var tableValues: [CustomStringConvertible] {
        return [self.hash.description, ByteCountFormatter.string(fromByteCount: Int64(self.size), countStyle: .memory), self.name]
    }
}

extension VersionInfoStruct: TextTableRepresentable {
    public static var columnHeaders: [String] {
        return ["blob", "size", "name", "date"]
    }
    
    public var tableValues: [CustomStringConvertible] {
        return [self.blob.description, ByteCountFormatter.string(fromByteCount: Int64(self.size), countStyle: .memory), self.name, self.date]
    }
}

