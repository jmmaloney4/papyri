// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

// https://stackoverflow.com/questions/39820602/using-secrandomcopybytes-in-swift
internal extension Array where Element == UInt8 {
    init(withRandomBytes count: Int) throws {
        var data = Data(count: count)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            fatalError("Couldn't generate random number")
        }
        
        self = data.bytes
    }
}
