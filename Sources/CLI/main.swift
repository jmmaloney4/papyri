import Vapor
import SwiftCLI
import Conduit

let mySessionClient = URLSessionClient(sessionConfiguration: URLSessionConfiguration.ephemeral, delegateQueue: OperationQueue())
