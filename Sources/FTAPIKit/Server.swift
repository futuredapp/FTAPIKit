import Foundation

public protocol ReadonlyServer {
    associatedtype APIError: Error

    var baseUri: URL { get }
    var urlSession: URLSession { get }
    var decoding: Decoding { get }
    var requestConfiguration: (inout URLRequest) -> Void { get }
}

public protocol Server: ReadonlyServer {
    var encoding: Encoding { get }
}

public extension ReadonlyServer {
    var urlSession: URLSession {
        .shared
    }

    var decoding: Decoding {
        JSONDecoding()
    }

    var requestConfiguration: (inout URLRequest) -> Void {
        { _ in }
    }
}

public extension Server {
    var encoding: Encoding {
        JSONEncoding()
    }
}
