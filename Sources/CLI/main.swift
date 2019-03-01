import Vapor
import SwiftCLI
import Alamofire
import Dispatch
import App
import Content

class ImportCommand: SwiftCLI.Command {
    let name = "import"
    let path = Parameter()
    
    func execute() throws {
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        var blobRes: DataResponse<Any>?
        var fileRes: DataResponse<Any>?
        
        let url = URL(fileURLWithPath: path.value)
        let blobEndpoint = URL(string: "http://localhost:8080/blob")!
        let fileEndpoint = URL(string: "http://localhost:8080/file")!
        
        Alamofire.upload(url, to: blobEndpoint, method: .post)
            .validate()
            .responseJSON(queue: queue) { res in
                blobRes = res
                sem.signal()
            }
        sem.wait()
        let blobJson = try JSONDecoder().decode(BlobInfoStruct.self, from: blobRes!.data!)
        
        let reqJson = CreateFileStruct(name: url.lastPathComponent, blob: blobJson.hash)
        Alamofire.request(fileEndpoint, method: HTTPMethod.post, parameters: try reqJson.asParameters(), encoding: JSONEncoding.default, headers: nil)
            .validate()
            .responseJSON(queue: queue) { res in
                fileRes = res
                sem.signal()
            }
        sem.wait()
        let fileJson = try JSONDecoder().decode(FileInfoStruct.self, from: fileRes!.data!)
        
        print("\(fileJson.hash)    \(fileJson.size)    \(fileJson.name)")
    }
}

let myCli = CLI(name: "papyri", version: "0.0.1")
myCli.commands = [ ImportCommand() ]
myCli.goAndExit()
