import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    router.get("blob") { req in
        return Blob.query(on: req).all().map({ $0.map({ $0.hash }) })
    }
    
    router.get("blob", String.parameter) { req -> EventLoopFuture<HTTPResponse> in
        let sha = try SHA256(withHex: req.parameters.next())
        return Blob.query(on: req).filter(\.hash == sha).first().map({ $0! })
            .map({ blob in
                return HTTPResponse(status: .ok, version: .init(major: 1, minor: 1), headers: .init(), body: try blob.loadData())
            })
    }
    
    router.post("blob", use: { req -> HTTPStatus in
        _ = try Blob(withData: req.http.body.data!).save(on: req)
        return HTTPStatus.created
    })
}
