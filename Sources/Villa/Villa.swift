import Foundation
import PathKit

struct Id {
    private var sha256: SHA256
    
    /*
    public enum IdType {
        case index
        case blob
    }
    private var type: IdType
    */
    init(withHex hash: String /* , type: IdType = .blob */) throws {
        self.sha256 = try SHA256(withHex: hash)
        // self.type = type
    }
}

public class Villa {
    public struct Paths {
        public static let config = Path.home + Path(".villa/config")
        public static let index = Path("index")
    }
    
    struct VillaConfig: Codable {
        var database: Path
    }
    
    var config: VillaConfig
    private var index: [Id] = []
    
    public init() throws {
        let decoder = JSONDecoder()
        self.config = try decoder.decode(VillaConfig.self, from: try! Paths.config.read())
        
        let indexPath = self.config.database + Paths.index
        if !indexPath.exists {
            try indexPath.write("")
        } else {
            let indexFile: String = try indexPath.read()
            for line in indexFile.split(separator: "\n") {
                self.index.append(try Id(withHex: String(line)))
            }
        }
    }
    
    func newFile(data: Data, name: String) {
        
    }
}

