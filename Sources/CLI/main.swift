import Foundation
import Dispatch
import SwiftCLI
import Alamofire
import SwiftyTextTable
import Content
import Client

class ImportCommand: SwiftCLI.Command {
    let name = "import"
    let path = Parameter()
    let json = Flag("-j", "--json")
    
    func execute() throws {
        let url = URL(fileURLWithPath: path.value)
        let file = try Client.importFile(path: url)

        if json.value {
            print(String(data: try JSONEncoder().encode(file), encoding: .utf8)!)
        } else {
            print(file.hash)
        }
    }
}

extension SHA256: ConvertibleFromString {
    public static func convert(from str: String) -> SHA256? {
        return try! SHA256(withHex: str)
    }
}

class UpdateCommand: SwiftCLI.Command {
    let name: String = "update"
    let hash = Parameter()
    let path = Parameter()
    
    func execute() throws {
        let sha = try SHA256(withHex: hash.value)
        let files = try Client.getAllFiles()
        let search = files.filter({ $0.hash == sha })
        
        if search.isEmpty {
            print("File \(hash) does not exist.")
            exit(1)
        }
        
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        let url = URL(fileURLWithPath: path.value)
        let blob = try Client.uploadBlob(path: url)
        let request = UpdateFileStruct(name: url.lastPathComponent, blob: blob.hash)
        
        let fileEndpoint = URL(string: "http://localhost:8080/file/\(sha)")!
        
        Alamofire.request(fileEndpoint, method: HTTPMethod.post, parameters: try request.asParameters(), encoding: JSONEncoding.default, headers: nil)
            .validate()
            .responseJSON(queue: queue) { res in
                sem.signal()
        }
        sem.wait()
        
        print("\(blob.hash)")
    }
}

class ListCommand: SwiftCLI.Command {
    var name: String = "list"
    
    func execute() throws {
        let files = try Client.getAllFiles()
        print(files.renderTextTable())
    }
}

class LogCommand: SwiftCLI.Command {
    var name: String = "log"
    var hash = Parameter()
    
    func execute() throws {
        let sha = try SHA256(withHex: hash.value)
        
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        let endpoint = URL(string: "http://localhost:8080/file/\(sha)/version")!
     
        var response: DataResponse<Any>?
        
        Alamofire.request(endpoint)
            .validate()
            .responseJSON(queue: queue) { res in
                response = res
                sem.signal()
        }
        sem.wait()
        
        print(String(data: response!.data!, encoding: .utf8)!)
        
        let decoder = JSONDecoder()
        if #available(OSX 10.12, *) {
            decoder.dateDecodingStrategy = .iso8601
        } else {
            // Fallback on earlier versions
            fatalError()
        }
        let versions = try decoder.decode([VersionInfoStruct].self, from: response!.data!)
        
        print(versions.renderTextTable())
    }
}

let myCli = CLI(name: "papyri", version: "0.0.1")
myCli.commands = [ ImportCommand(), ListCommand(), UpdateCommand(), LogCommand() ]
myCli.goAndExit()
