import Vapor
import SwiftCLI
import Alamofire
import Dispatch
import App
import Content
import SwiftyTextTable

extension FileInfoStruct: TextTableRepresentable {
    public static var columnHeaders: [String] {
        return ["hash", "size", "name"]
    }
    
    public var tableValues: [CustomStringConvertible] {
        return [self.hash.description, ByteCountFormatter.string(fromByteCount: Int64(self.size), countStyle: .memory), self.name]
    }
}

class ImportCommand: SwiftCLI.Command {
    let name = "import"
    let paths = CollectedParameter()
    let json = Flag("-j", "--json", description: "Print the resultant file as JSON.", defaultValue: false)
    
    func execute() throws {
        print("\(paths.value)")
        let urls = paths.value.map({ URL(fileURLWithPath: $0) })
        let files = try urls.map({ try importFile(path: $0) })

        if json.value {
            print(try JSONEncoder().encode(files))
        } else {
            print(files.renderTextTable())
        }
    }
    
    func importFile(path: URL) throws -> FileInfoStruct {
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        var blobRes: DataResponse<Any>?
        var fileRes: DataResponse<Any>?
        
        let blobEndpoint = URL(string: "http://localhost:8080/blob")!
        let fileEndpoint = URL(string: "http://localhost:8080/file")!
        
        Alamofire.upload(path, to: blobEndpoint, method: .post)
            .validate()
            .responseJSON(queue: queue) { res in
                blobRes = res
                sem.signal()
        }
        sem.wait()
        var blobJson: BlobInfoStruct
        do {
             blobJson = try JSONDecoder().decode(BlobInfoStruct.self, from: blobRes!.data!)
        } catch {
            print(error)
            fatalError()
        }
        let reqJson = CreateFileStruct(name: path.lastPathComponent, blob: blobJson.hash)
        
        Alamofire.request(fileEndpoint, method: HTTPMethod.post, parameters: try reqJson.asParameters(), encoding: JSONEncoding.default, headers: nil)
            .validate()
            .responseJSON(queue: queue) { res in
                fileRes = res
                sem.signal()
        }
        sem.wait()
        
        return try JSONDecoder().decode(FileInfoStruct.self, from: fileRes!.data!)
    }
}

class ListCommand: SwiftCLI.Command {
    var name: String = "list"
    
    func execute() throws {
        let files = try getAllFiles()
        print(files.renderTextTable())
    }
    
    func getAllFiles() throws -> [FileInfoStruct] {
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        let fileEndpoint = URL(string: "http://localhost:8080/file")!
        
        var response: DataResponse<Any>?
        
        Alamofire.request(fileEndpoint).validate().responseJSON(queue: queue) { res in
            response = res
            sem.signal()
        }
        sem.wait()
        
        return try JSONDecoder().decode([FileInfoStruct].self, from: response!.data!)
    }
    
}

let myCli = CLI(name: "papyri", version: "0.0.1")
myCli.commands = [ ImportCommand(), ListCommand() ]
myCli.goAndExit()
