import Vapor
import Alamofire

public extension Content {
    public func asParameters() throws -> Alamofire.Parameters {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

public struct BlobInfoStruct: Content {
    public var hash: SHA256
    
    public init(hash: SHA256) {
        self.hash = hash
    }
}

public struct FileInfoStruct: Content {
    public var name: String
    public var hash: SHA256
    public var size: Int
    
    public init(name: String, hash: SHA256, size: Int) {
        self.name = name
        self.hash = hash
        self.size = size
    }
}

public struct CreateFileStruct: Content {
    public var name: String
    public var blob: SHA256
    
    public init(name: String, blob: SHA256) {
        self.name = name
        self.blob = blob
    }
}


public struct UpdateFileStruct: Content {
    public var name: String?
    public var blob: SHA256
    
    public init(name: String, blob: SHA256) {
        self.name = name
        self.blob = blob
    }
}
