
import PathKit

enum ObjectType: String {
    case blob
    case commit
    case branch
    case tag
    case group
    case file
}

protocol Object {
    
}

struct File: Object {
    public var id: Hash
    public var name: String
    // var dateAdded: Date
    // var fileType: FileType
    var branches: [Hash]
    var tags: [Hash]
}

struct Branch: Object {

}

struct Tag: Object {

}
