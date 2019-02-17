import Vapor

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
        return Blob.query(on: req).all()
    }
    
    router.post("blob", use: { req -> HTTPStatus in
        _ = try Blob(withData: req.http.body.data!).save(on: req)
        return HTTPStatus.created
    })
}
