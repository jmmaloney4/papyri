// Copyright © 2019 Jack Maloney. All Rights Reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Villa
import SwiftCLI

let papyri = CLI(name: "papyri")
papyri.commands = [ImportCommand(), ListCommand()]
papyri.goAndExit()

