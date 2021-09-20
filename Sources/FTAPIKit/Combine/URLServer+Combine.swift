import Foundation
#if canImport(Combine)
import Combine

@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Note: Canceling this chain will result in the abortion of the URLSessionTask.
    /// - Note: This call maps `func call(endpoint: Endpoint, completion: @escaping (Result<Void, ErrorType>) -> Void) -> URLSessionTask?` to the Combine API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Returns: On success void, otherwise error.
    func publisher(endpoint: Endpoint) -> AnyPublisher<Void, ErrorType> {
        Publishers.Endpoint { completion in
            self.call(endpoint: endpoint, completion: completion)
        }
        .eraseToAnyPublisher()
    }

    /// Performs call to endpoint which returns an arbitrary data in the HTTP response, that won't be parsed by the decoder of the
    /// server.
    /// - Note: Canceling this chain will result in the abortion of the URLSessionTask.
    /// - Note: This call maps `func call(data endpoint: Endpoint, completion: @escaping (Result<Data, ErrorType>) -> Void) -> URLSessionTask?` to the Combine API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Returns: On success plain data, otherwise error.
    func publisher(data endpoint: Endpoint) -> AnyPublisher<Data, ErrorType> {
        Publishers.Endpoint { completion in
            self.call(data: endpoint, completion: completion)
        }
        .eraseToAnyPublisher()
    }

    /// Performs call to endpoint which returns data which will be parsed by the server decoder.
    /// - Note: Canceling this chain will result in the abortion of the URLSessionTask.
    /// - Note: This call maps `func call<EP: ResponseEndpoint>(response endpoint: EP, completion: @escaping (Result<EP.Response, ErrorType>) -> Void) -> URLSessionTask?` to the Combine API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Returns: On success instance of the required type, otherwise error.
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
