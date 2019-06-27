// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftCLI
import Villa
import SwiftyTextTable

class ListCommand: Command {
    var name: String = "list"
    
    func execute() throws {
        let files = try Villa.shared.allFiles()
        
        let id = TextTableColumn(header: "id")
        let name = TextTableColumn(header: "name")
        
        var table = TextTable(columns: [id, name])
        
        files.forEach { file in
            table.addRow(values: [file.id, file.name])
        }
        
        print(table.render())
    }
}
