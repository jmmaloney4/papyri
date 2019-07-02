//
//  Vault.swift
//  CYaml
//
//  Created by Jack Maloney on 6/30/19.
//

import Foundation
import SwiftCLI
import Villa
import CryptoSwift
import PathKit
import SwiftyTextTable

class VaultCommands: CommandGroup {
    let name: String = "vault"
    let shortDescription: String = "Deal with Vaults."
    
    let children: [Routable] = [ListVaultsCommand(), CreateVaultCommand()]
}

class ListVaultsCommand: Command {
    var name: String = "list"
    
    func execute() throws {
        let name = TextTableColumn(header: "Name")
        let cipher = TextTableColumn(header: "Cipher")
        let id = TextTableColumn(header: "Path")
        
        var table = TextTable(columns: [name, cipher, id])
        
        Villa.shared.vaults.forEach { vault in
            table.addRow(values: [vault.name, vault.key?.variant.name ?? "No Encryption", vault.path])
        }
        
        print(table.render())
    }
}

class CreateVaultCommand: Command {
    var name: String = "create"
    
    var vaultName = Parameter()
    var path = Parameter()
    
    let aes128 = Flag("--aes128", description: "Generate an AES-128 key. This is the default.")
    let aes192 = Flag("--aes192", description: "Generate an AES-192 key.")
    let aes256 = Flag("--aes256", description: "Generate an AES-256 key. (Slowest, Best security).")
    
    func execute() throws {
        let vaultPath = Path(path.value).normalize()
        if vaultPath.exists {
            let input = Input.readLine(prompt: "Create new Vault in existing directory \(vaultPath)? [Y/n]: ")
            guard input.range(of: "(y|Y).*", options: .regularExpression) != nil else {
                exit(1)
            }
        }
        
        print("Creating a new Vault '\(vaultName.value)' at '\(vaultPath)'.")
        
        var variant: AES.Variant = .aes128
        if aes128.value {
            // default
        } else if aes192.value {
            variant = .aes192
        } else if aes256.value {
            variant = .aes256
        }
        
        print("Generating a new \(variant.name) key...")
        
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
        
        let vault = try Vault.createVault(atPath: vaultPath, withName: vaultName.value, andPassword: password!, variant: variant)
        Villa.shared.vaults.append(vault)
    }
}
