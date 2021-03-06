import FluentSQLite
import Vapor
import Content

struct Blob: SQLiteModel, Migration, Parameter {
    var id: Int?
    var hash: SHA256
    lazy var data: Data = try! Blob.read(self.hash)
    
    var size: Int { return try! self.loadData().count }
    
    init(withData data: Data) throws {
        self.hash = try Blob.write(data)
    }
    
    static func write(_ data: Data) throws -> SHA256 {
        let hash = SHA256(withData: data)
        try FileManager.default.createDirectory(atPath: "/Users/jack/.papyri/obj/\(getDBPrefixDirPath(hash))", withIntermediateDirectories: true)
        do {
        try data.write(to: urlForHash(hash))
        } catch {
            print(error)
        }
        
        return hash
    }
    
    func loadData() throws -> Data {
        return try Blob.read(hash)
    }
    
    static func read(_ hash: SHA256) throws -> Data {
        return try Data(contentsOf: urlForHash(hash))
    }
    
    static func urlForHash(_ hash: SHA256) -> URL {
        return URL(fileURLWithPath: "/Users/jack/.papyri/obj/\(getDBPathForHash(hash))")
    }
    
    static func getDBPathForHash(_ sha: SHA256) -> String {
        let hex = sha.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        let part2 = hex.suffix(from: splitIndex)
        return "\(part1)/\(part2)"
    }
    
    static func getDBPrefixDirPath(_ sha: SHA256) -> String {
        let hex = sha.hex
        let splitIndex = hex.index(hex.startIndex, offsetBy: 2)
        let part1 = hex.prefix(upTo: splitIndex)
        return String(part1)
    }
    
    static func find(hash: SHA256, on db: DatabaseConnectable) -> Future<Blob> {
        let rv = Blob
            .query(on: db)
            .filter(\.hash == hash)
        let count = rv.count().map({
            switch $0 {
            case 0: throw PYError.blobDoesNotExist
            case 1: break;
            default: fatalError()
            }
        })
        
        return rv.first().unwrap(or: PYError.unknown)
            .and(count).map({ return $0.0 }) // Ensure error gets propegated properly
        
    }
}
