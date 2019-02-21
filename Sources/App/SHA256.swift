// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Crypto
import Vapor

public struct SHA256: Codable, Content, CustomStringConvertible, Equatable {
    public internal(set) var bytes: [UInt8]
    
    public init(withData data: Data) {
        guard let digest = try? Crypto.SHA256.hash(data) else {
            fatalError()
        }
        self.bytes = [UInt8](digest.convertToData())
    }
    
    public init(withHex hex: String) throws {
        self.bytes = hex.hexa2Bytes
        guard self.bytes.count == 32 else {
            fatalError()
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        if str.count != 64 {
            // Fluent needs to init an empty thing. Its dumb.
            // Not sure why this happens or where it is documented.
            // print(str)
            self.init(withData: Data())
            return
        }
        try self.init(withHex: str)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.hex)
    }
    
    public var hex: String {
        return self.bytes.reduce(String(), { $0.appendingFormat("%02x", $1) })
    }
    public var description: String { return self.hex }
}

fileprivate extension StringProtocol {
    var hexa2Bytes: [UInt8] {
        guard self.count > 2 else {
            return []
        }
        let hexa = Array(self)
        return stride(from: 0, to: count, by: 2).compactMap { UInt8(String(hexa[$0...$0.advanced(by: 1)]), radix: 16) }
    }
}

extension SHA256: ReflectionDecodable {
    public static func reflectDecoded() throws -> (SHA256, SHA256) {
        return (
            try SHA256(withHex: Array(repeating: 0, count: 64).map({"\($0)"}).joined()),
            try SHA256(withHex: Array(repeating: 1, count: 64).map({"\($0)"}).joined())
        )
    }
}
