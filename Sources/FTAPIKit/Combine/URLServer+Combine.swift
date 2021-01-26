import Foundation
#if canImport(Combine)
import Combine

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension URLServer {
    func publisher(endpoint: Endpoint) -> AnyPublisher<Void, ErrorType> {
        Publishers.Endpoint { completion in
            self.call(endpoint: endpoint, completion: completion)
        }
        .eraseToAnyPublisher()
    }

    func publisher(data endpoint: Endpoint) -> AnyPublisher<Data, ErrorType> {
        Publishers.Endpoint { completion in
            self.call(data: endpoint, completion: completion)
        }
        .eraseToAnyPublisher()
    }

    func publisher<EP: ResponseEndpoint>(response endpoint: EP) -> AnyPublisher<EP.Response, ErrorType> {
        Publishers.Endpoint { completion in
            self.call(response: endpoint, completion: completion)
        }
        .eraseToAnyPublisher()
    }

    func publisher(download endpoint: Endpoint) -> AnyPublisher<URL, ErrorType> {
        Publishers.Endpoint { completion in
            self.download(endpoint: endpoint, completion: completion)
        }
        .eraseToAnyPublisher()
    }
}

#endif
