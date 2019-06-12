//
//  PathKit+Codable.swift
//  Villa
//
//  Created by Jack Maloney on 6/11/19.
//

import Foundation
import PathKit

extension Path: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self.init(raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.normalize().string)
    }
}
