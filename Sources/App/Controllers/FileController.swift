//
//  FileController.swift
//  App
//
//  Created by Jack Maloney on 2/22/19.
//

import Foundation
import Vapor
import Async

struct FileController {
    struct FileInfoStruct: Content {
        var name: String
        var hash: SHA256
        var size: Int
    }
    
    static func getAllFiles(_ req: Request) -> Future<[FileInfoStruct]> {
        let files = File.query(on: req).all()
        
        return files.flatMap({ files -> Future<[FileInfoStruct]> in
            return files.map({ file -> Future<FileInfoStruct> in
                Version.find(file.latest, on: req).flatMap({ ver -> Future<FileInfoStruct> in
                    return Blob.find(ver!.blob, on: req).map({ return FileInfoStruct(name: ver!.name, hash: file.hash, size: try $0!.loadData().count) })
                })
            }).flatten(on: req)
        })
    }
    /*
    static func getFile(_ req: Request) -> HTTPResponse {
//        req.parameters.next()
    }
 
    static func createFile(_ req: Request) -> Future<FileInfoStruct> {
        
    }
    */
    static func addRoutes(_ router: Router) {
        router.get("files", use: FileController.getAllFiles)
    }
}
