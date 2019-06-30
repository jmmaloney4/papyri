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

class KeyCommands: CommandGroup {
    let name: String = "key"
    let shortDescription: String = "Deal with Encryption Keys."
    
    let children: [Routable] = [ListKeysCommand(), AddKeyCommand()]
}

class ListKeysCommand: Command {
    var name: String = "list"
    func execute() throws {
        for key in Villa.shared.keys {
            print("\(key.shortHash)")
        }
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
        let name = Input.readLine(prompt: "Enter a name for this key: ")
        let password = Input.readLine(prompt: "Enter a password for this key: ", secure: true)
        
        let key = try Villa.shared.generateNewKey(name: name, variant: variant, password: password)
        print(key.shortHash)
    }
}
