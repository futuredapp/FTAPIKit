import Combine
import Foundation

@available(OSX 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension URLServer {
    func publisher(endpoint: Endpoint) -> AnyPublisher<Data, ErrorType> {
        request(endpoint: endpoint)
            .publisher
            .flatMap { request in
                self.urlSession
                    .dataTaskPublisher(for: request)
                    .mapError { ErrorType(data: nil, response: nil, error: $0, decoding: self.decoding) ?? .unhandled }
            }
            .map(\.data)
            .eraseToAnyPublisher()
    }

    func publisher<EP: ResponseEndpoint>(response endpoint: EP) -> AnyPublisher<EP.Response, ErrorType> {
        publisher(endpoint: endpoint)
            .tryMap(self.decoding.decode)
            .mapError { error in
                if let error = error as? ErrorType {
                    return error
                } else if let error = ErrorType(data: nil, response: nil, error: error, decoding: self.decoding) {
                    return error
                }
                return .unhandled
            }.eraseToAnyPublisher()
    }
}
