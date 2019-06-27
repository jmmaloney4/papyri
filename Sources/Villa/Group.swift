//
//  Group.swift
//  CryptoSwift
//
//  Created by Jack Maloney on 6/16/19.
//

import Foundation

struct Group: Object {
    var id: Hash
    var files: [Hash]
}

protocol Object {
    
}

protocol MetadataObject: Object {
    
}

protocol Blob {
    
}
