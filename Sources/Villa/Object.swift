// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import PathKit

enum ObjectType: String {
    case blob
    case commit
    case branch
    case tag
    case group
    case file
}

protocol Object {
    
}

struct File: Object {
    public var id: Hash
    public var name: String
    // var dateAdded: Date
    // var fileType: FileType
    var branches: [Hash]
    var tags: [Hash]
}

struct Branch: Object {

}

struct Tag: Object {

}
