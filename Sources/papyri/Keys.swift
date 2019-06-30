//
//  Keys.swift
//  CYaml
//
//  Created by Jack Maloney on 6/29/19.
//

import Foundation
import SwiftCLI
import Villa
import CryptoSwift
import SwiftyTextTable

class KeyCommands: CommandGroup {
    let name: String = "key"
    let shortDescription: String = "Deal with Encryption Keys."
    
    let children: [Routable] = [ListKeysCommand(), AddKeyCommand(), DumpKeyCommand()]
}

class ListKeysCommand: Command {
    var name: String = "list"
    func execute() throws {
        let name = TextTableColumn(header: "name")
        let cipher = TextTableColumn(header: "cipher")
        let id = TextTableColumn(header: "id")
        
        var table = TextTable(columns: [name, cipher, id])
        
        Villa.shared.keys.forEach { key in
            table.addRow(values: [key.name, key.variant.name, key.shortHash])
        }
        
        print(table.render())
    }
}

class AddKeyCommand: Command {
    var name: String = "add"
    
    let aes128 = Flag("--aes128", description: "Generate an AES-128 key. This is the default.")
    let aes192 = Flag("--aes192", description: "Generate an AES-192 key.")
    let aes256 = Flag("--aes256", description: "Generate an AES-256 key. (Slowest, Best security).")
    
    func execute() throws {
        var variant: AES.Variant = .aes128
        if aes128.value {
            // default
        } else if aes192.value {
            variant = .aes192
        } else if aes256.value {
            variant = .aes256
        }
        
        print("Generating a new \(variant.name) key...")
        let name = Input.readLine(prompt: "Enter a name for this key: ", validation: Villa.shared.keys.map({ Validation.rejecting($0.name) }))
        
        var password: String? = nil
        while true {
            let password1 = Input.readLine(prompt: "Enter a password for this key: ", secure: true)
            let password2 = Input.readLine(prompt: "Re-Enter: ", secure: true)
            
            if password1 == password2 {
                password = password1
                break
            } else {
                print("Passwords do not match.")
                continue
            }
        }
        
        
        
        let key = try Villa.shared.generateNewKey(name: name, variant: variant, password: password!)
        print(key.shortHash)
    }
}

class DumpKeyCommand: Command {
    var name: String = "dump"
    var force = Flag("--force", description: "This is a BAD IDEA. Don't Dump your *decrypted* keys unless you know what you're doing.")
    var key = Parameter()
    
    func execute() throws {
        guard force.value else {
            print("I won't do it without '--force'.")
            exit(1)
        }
        
        if var matched = Villa.shared.getKeyWithName(key.value) {
            let password = Input.readLine(prompt: "Enter a password for \(key.value): ", secure: true)
            if try matched.attemptDecryption(withPassword: password) {
                print(matched.decrypted!.toHexString())
            } else {
                print("Incorrect Password.")
                exit(1)
            }
        }
    }
}
