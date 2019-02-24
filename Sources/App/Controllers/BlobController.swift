//
//  BlobController.swift
//  App
//
//  Created by Jack Maloney on 2/21/19.
//

import Foundation
import Fluent
import Vapor

struct BlobController {
    static func getAllBlobHashes(_ req: Request) -> Future<[SHA256]> {
        return Blob.query(on: req).all().map({ $0.map({ $0.hash }) })
    }
    
    static func getSpecificBlob(_ req: Request) throws -> Future<HTTPResponse> {
        let sha = try SHA256(withHex: req.parameters.next())
        return Blob.query(on: req).filter(\.hash == sha).first().map({ $0! })
            .map({ blob in
                return HTTPResponse(status: .ok, body: try blob.loadData())
            })
    }

    struct BlobInfoStruct: Content {
        var hash: SHA256
    }
    
    static func postBlob(_ req: Request) throws -> Future<Response> {
        let blob = try Blob(withData: req.http.body.data!).save(on: req)
        let info = blob.map({ BlobInfoStruct(hash: $0.hash) })
        return info.encode(status: .created, for: req)
    }
    
    static func addRoutes(_ router: Router) {
        router.get("blob", use: BlobController.getAllBlobHashes)
        router.get("blob", String.parameter, use: BlobController.getSpecificBlob)
        router.post("blob", use: BlobController.postBlob)
    }
}

