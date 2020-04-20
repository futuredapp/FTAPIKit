import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension URLServer {
    func publisher(endpoint: Endpoint) -> Publishers.Endpoint<Void, ErrorType> {
        Publishers.Endpoint { completion -> URLSessionTask? in
            self.call(endpoint: endpoint, completion: completion)
        }
    }

    func publisher(data endpoint: Endpoint) -> Publishers.Endpoint<Data, ErrorType> {
        Publishers.Endpoint { completion -> URLSessionTask? in
            self.call(data: endpoint, completion: completion)
        }
    }

    func publisher<EP: ResponseEndpoint>(response endpoint: EP) -> Publishers.Endpoint<EP.Response, ErrorType> {
        Publishers.Endpoint { completion -> URLSessionTask? in
            self.call(response: endpoint, completion: completion)
        }
    }
}
