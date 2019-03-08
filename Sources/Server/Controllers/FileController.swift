//
//  FileController.swift
//  App
//
//  Created by Jack Maloney on 2/22/19.
//

import Foundation
import Vapor
import Fluent
import Content

public struct FileController {
    static func getAllFiles(_ req: Request) -> Future<[FileInfoStruct]> {
        return File.query(on: req).all().flatMap({ files -> Future<[FileInfoStruct]> in
            return files.map({ file -> Future<FileInfoStruct> in
                Version.find(file.latest, on: req).flatMap({ ver -> Future<FileInfoStruct> in
                    return Blob.find(ver!.blob, on: req).map({ return FileInfoStruct(name: ver!.name, hash: file.hash, size: $0!.size) })
                })
            }).flatten(on: req)
        })
    }
    
    static func getFile(_ req: Request) throws -> Future<HTTPResponse> {
        let sha = try SHA256(withHex: req.parameters.next())
        let file = File.query(on: req).filter(\.hash == sha).first()
        let blob = file.map({ $0!.latest }).flatMap{ Version.find($0, on: req) }.flatMap({ Blob.find($0!.blob, on: req) })
        return blob.map({ HTTPResponse(status: .ok, body: try $0!.loadData()) })
    }
    
    static func createFile(_ req: Request) throws -> Future<Response> /* FileInfoStruct */ {
        return try req.content.decode(CreateFileStruct.self)
            .flatMap({ body -> Future<Response> in
                
                return Blob.find(hash: body.blob, on: req)
                    .flatMap({ blob -> Future<Response> in
                        
                        Version.createWith(blob: blob, name: body.name, on: req)
                            .flatMap({ ver -> Future<Response> in
                                
                                return File(id: nil, hash: blob.hash, latest: ver.id!)
                                    .save(on: req)
                                    .flatMap { file -> Future<Response> in
                                        
                                        return FileInfoStruct(name: body.name, hash: body.blob, size: blob.size)
                                            .encode(status: HTTPStatus.created, for: req)
                                }
                            })
                    })
            })
    }
    
    static func updateFile(_ req: Request) throws -> Future<Response> /* FileInfoStruct */ {
        let sha = try SHA256(withHex: req.parameters.next())
        let file = File.query(on: req).filter(\.hash == sha).first()
        
        return try req.content.decode(UpdateFileStruct.self)
            .flatMap({ body -> EventLoopFuture<Response> in
                // Find the blob
                return Blob.find(hash: body.blob, on: req)
                    .and(file)
                    .flatMap({ (arg) -> EventLoopFuture<Response> in
                        let (blob, file) = arg
                        
                        return file.map({ $0.latest }).flatMap {
                            Version.find($0, on: req).flatMap {
                                $0!.createSubsequentVersion(blob: blob, name: body.name, on: req)
                            }
                        }
                        .unsafelyUnwrapped
                        .flatMap({ ver -> Future<Response> in
                                // Save the new file
                                var newFile = file!
                                newFile.latest = ver.id!
                                return newFile.update(on: req).flatMap({ _ in
                                    FileInfoStruct(name: ver.name, hash: newFile.hash, size: blob.size)
                                        .encode(status: HTTPStatus.ok, for: req)
                                })
                        })
                    })
            })
    }
    
    static func getAllVersions(_ req: Request) throws -> Future<[VersionInfoStruct]> {
        let sha = try SHA256(withHex: req.parameters.next())
        let file = File.query(on: req).filter(\.hash == sha).first()
        
        return file.flatMap {
            return Version.find($0!.latest, on: req).flatMap {
                return getNextVersion($0!.id!, on: req, current: [])
            }
        }
    }
    
    static func getNextVersion(_ previous: Version.ID, on req: Request, current: [Future<VersionInfoStruct>]) -> Future<[VersionInfoStruct]> {
        let version = Version.find(previous, on: req)
        return version.flatMap { ver -> Future<[VersionInfoStruct]> in
            let info = Blob.find(ver!.blob, on: req).map { blob -> VersionInfoStruct in
                return VersionInfoStruct(name: ver!.name, blob: blob!.hash, size: blob!.size, date: ver!.date)
            }
            
            var rv = current
            rv.append(info)
            
            if ver!.previous != nil {
                return getNextVersion(ver!.previous!, on: req, current: rv)
            } else {
                return rv.flatten(on: req)
            }
        }
    }
    
    static func addRoutes(_ router: Router) {
        router.get("file", use: FileController.getAllFiles)
        router.get("file", String.parameter, use: FileController.getFile)
        router.post("file", use: FileController.createFile)
        router.post("file", String.parameter, use: FileController.updateFile)
        
        router.get ("file", String.parameter, "version", use: FileController.getAllVersions)
    }
}
