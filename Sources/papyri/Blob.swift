// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftCLI

class BlobCommands: CommandGroup {
    var name: String = "blob"
    var shortDescription: String = "Commands that deal with Blob."
    var children: [Routable] = []
}

class ListBlobsCommand: Command {
    var name: String = "list"
    
    func execute() throws {
        
    }
}
