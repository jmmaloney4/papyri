// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

enum FileType: String, Codable {
    typealias RawValue = String
    
    case plain = "text/plain"
    case pdf = "application/pdf"
    case markdown = "text/markdown"
    
    static var extensions: [FileType:[String]] = [
        .plain: [".txt"],
        .pdf: [".pdf"],
        .markdown: [".md"]
    ]
    
    static func forExtension(_ ext: String) -> FileType? {
        for (type, exts) in extensions {
            if exts.contains(ext) {
                return type
            }
        }
        return nil
    }
}
