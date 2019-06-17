//
//  Group.swift
//  CryptoSwift
//
//  Created by Jack Maloney on 6/16/19.
//

import Foundation

struct Group: Object {
    var id: SHA256
    var files: [SHA256]
}

