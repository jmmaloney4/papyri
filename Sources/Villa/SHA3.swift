// Copyright © 2018-2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import CryptoSwift

public struct Hash: Codable, CustomStringConvertible, Hashable {
    public fileprivate(set) var bytes: [UInt8]
    
    public init(withData data: Data) {
        self.bytes = data.sha3(.sha256).bytes
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
            fatalError("Couldn't decode SHA3-256 hex: \(str)")
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
