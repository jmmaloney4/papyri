// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftCLI
import PathKit
import Villa
import SwiftyTextTable

class ImportCommand: Command {
    var name: String = "import"
    let paths = CollectedParameter()
    
    func execute() throws {
        print(paths.value)
        
        var files: [File] = []
        try paths.value.forEach {
            let path = Path($0)
            let file = try Villa.shared.newFile(data: try path.read(), name: path.lastComponent)
            files.append(file)
        }
        
        let id = TextTableColumn(header: "id")
        let name = TextTableColumn(header: "name")
        
        var table = TextTable(columns: [id, name])
        
        files.forEach { file in
            table.addRow(values: [file.id, file.name])
        }
        
        print(table.render())
    }
}
