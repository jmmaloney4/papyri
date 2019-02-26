import Vapor
import SwiftCLI
import Alamofire
import Dispatch

// let mySessionClient = URLSessionClient(sessionConfiguration: URLSessionConfiguration.ephemeral, delegateQueue: OperationQueue())
/*
 let requestBuilder = HTTPRequestBuilder(url: URL(string: "http://localhost:8080/")!)
 requestBuilder.method = .GET
 let req = try requestBuilder.build()
 
 mySessionClient.begin(request: req) { (data, res, err) in
 print(String(data: data!, encoding: .utf8)!)
 }
 
 sleep(100)
 
 */
class ImportCommand: SwiftCLI.Command {
    let name = "import"
    let path = Parameter()
    
    func execute() throws {
        // let data = try Data(contentsOf: URL(fileURLWithPath: path.value))
        print("hola")
        let sem = DispatchSemaphore(value: 0)
        Alamofire.upload(URL(fileURLWithPath: "/Users/jack/Developer/papyri/poem.txt"), to: "http://localhost:8080/blob", method: .post)
            .validate()
            .responseJSON { res in
                print(res.error!)
                print(String(data: res.data!, encoding: .utf8)!)
                print("Hello, \(res)")
                sem.signal()
            }
        
        sem.wait()
        
        
    }
}

let myCli = CLI(name: "greeter", version: "1.0.0", description: "Greeter - your own personal greeter")
myCli.commands = [ ImportCommand() ]
myCli.goAndExit()
