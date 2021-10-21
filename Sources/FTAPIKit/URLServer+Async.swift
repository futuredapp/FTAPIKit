#if swift(>=5.5)
import Foundation

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Note: This call maps ``call(endpoint:completion:)`` to the async/await API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws in case that result is .failure
    /// - Returns: Void on success
    func call(endpoint: Endpoint) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            call(endpoint: endpoint) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Performs call to endpoint which returns an arbitrary data in the HTTP response, that should not be parsed by the decoder of the
    /// server.
    /// - Note: This call maps ``call(data:completion:)`` to the async/await API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws in case that result is .failure
    /// - Returns: Plain data returned with the HTTP Response
    func call(data endpoint: Endpoint) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            call(data: endpoint) { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Performs call to endpoint which returns data that are supposed to be parsed by the decoder of the instance
    /// conforming to ``Server`` in the HTTP response.
    /// - Note: This call maps  ``call(response:completion:)`` to the async/await API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws in case that result is .failure
    /// - Returns: Instance of the required type
    func call<EP: ResponseEndpoint>(response endpoint: EP) async throws -> EP.Response {
        return try await withCheckedThrowingContinuation { continuation in
            call(response: endpoint) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
#endif
