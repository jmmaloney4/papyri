import Foundation
import PathKit

enum FileType: String, Codable {
    typealias RawValue = String
    
    case plain = "text/plain"
    case pdf = "application/pdf"
    case markdown = "text/markdown"
    
    static var extensions: [FileType:[String]] = [
        .plain: [".txt"],
        .pdf: [".pdf"],
        .markdown: [".md"]
    ]
    
    static func forExtension(_ ext: String) -> FileType? {
        for (type, exts) in extensions {
            if exts.contains(ext) {
                return type
            }
        }
        return nil
    }
}

struct Branch: Codable, Hashable {
    var id: SHA256
    var name: String
    var head: SHA256
    
    static func == (lhs: Branch, rhs: Branch) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

struct Tag: Codable, Hashable {
    var id: SHA256
    var name: String
    var commit: SHA256
}

struct IndexFile: Codable {
    var id: SHA256
    var fileName: String
    var dateAdded: Date
    var fileType: FileType
    var branches: [Branch:SHA256]
    var tags: [Tag:SHA256]
    
    init(fileName name: String) {
        self.fileName = name
        self.dateAdded = Date()
        self.fileType = FileType.forExtension(Path(name).extension ?? "") ?? .plain
        self.branches = [:]
        self.tags = [:]
        self.id = SHA256(withData: "\(self.fileName)\(self.dateAdded)".data(using: .utf8)!)
    }
}

struct Blob: Codable {
    var id: SHA256
    var data: Data
    
    
}

public class Villa {
    public struct Paths {
        public static let config = Path.home + Path(".villa/config")
        public static let index = Path("index")
    }
    
    struct VillaConfig: Codable {
        var database: Path
        
        var indexPath: Path {
            return (self.database + Paths.index).normalize()
        }
    }
    
    var config: VillaConfig
    private var index: [SHA256] = []
    
    public init() throws {
        let decoder = JSONDecoder()
        self.config = try decoder.decode(VillaConfig.self, from: try! Paths.config.read())
        self.config.database = self.config.database.normalize().absolute()
        
        if !self.config.indexPath.exists {
            try self.config.indexPath.write("")
        } else {
            let indexFile: String = try self.config.indexPath.read()
            for line in indexFile.split(separator: "\n") {
                self.index.append(try SHA256(withHex: String(line)))
            }
        }
    }
    
    func writeIndex() throws {
        try index.map({ $0.hex })
            .joined(separator: "\n")
            .write(to: URL(fileURLWithPath: config.indexPath.string), atomically: true, encoding: .utf8)
    }
    
    func newFile(data: Data, name: String) throws {
        let index = IndexFile(fileName: name)
        self.index.append(index.id)
        try self.writeIndex()
        
        
    }
}

