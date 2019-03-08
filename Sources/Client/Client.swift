import Foundation
import Dispatch
import Content
import Alamofire

public class Client {
    public static func uploadBlob(path: URL) throws -> BlobInfoStruct {
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        var response: DataResponse<Any>?
        
        let blobEndpoint = URL(string: "http://localhost:8080/blob")!
        
        Alamofire.upload(path, to: blobEndpoint, method: .post)
            .validate()
            .responseJSON(queue: queue) { res in
                response = res
                sem.signal()
        }
        sem.wait()
        
        return try JSONDecoder().decode(BlobInfoStruct.self, from: response!.data!)
    }
    
    public static func importFile(path: URL) throws -> FileInfoStruct {
        let queue = DispatchQueue(label: "Request Callbacks")
        let sem = DispatchSemaphore(value: 0)
        
        var fileRes: DataResponse<Any>?
        let fileEndpoint = URL(string: "http://localhost:8080/file")!
        
        let blob = try Client.uploadBlob(path: path)
        let reqJson = CreateFileStruct(name: path.lastPathComponent, blob: blob.hash)
        
        Alamofire.request(fileEndpoint, method: HTTPMethod.post, parameters: try reqJson.asParameters(), encoding: JSONEncoding.default, headers: nil)
            .validate()
            .responseJSON(queue: queue) { res in
                fileRes = res
                sem.signal()
        }
        sem.wait()
        
        return try JSONDecoder().decode(FileInfoStruct.self, from: fileRes!.data!)
    }
    
    public static func getAllFiles() throws -> [FileInfoStruct] {
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
