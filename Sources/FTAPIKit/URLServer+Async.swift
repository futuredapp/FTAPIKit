import Foundation
#if os(Linux)
import FoundationNetworking
#endif

// This extension is duplicated to support Xcode 13.0 and Xcode 13.1,
// where backported concurrency is not available.

// Support of async-await for Xcode 13.2+.
#if swift(>=5.5.2)
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Note: This call maps ``call(endpoint:completion:)`` to the async/await API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws in case that result is .failure
    /// - Returns: Void on success
    func call(endpoint: Endpoint) async throws {
        var task: URLSessionTask?
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = call(endpoint: endpoint) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: { [task] in
            task?.cancel()
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
        var task: URLSessionTask?
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = call(data: endpoint) { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: { [task] in
            task?.cancel()
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
        var task: URLSessionTask?
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = call(response: endpoint) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: { [task] in
            task?.cancel()
        }
    }
}

// Support of async-await for Xcode 13 and 13.1.
#elseif swift(>=5.5)
@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
p@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Note: This call maps ``call(endpoint:completion:)`` to the async/await API
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws in case that result is .failure
    /// - Returns: Void on success
    func call(endpoint: Endpoint) async throws {
        var task: URLSessionTask?
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = call(endpoint: endpoint) { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: { [task] in
            task?.cancel()
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
        var task: URLSessionTask?
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = call(data: endpoint) { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: { [task] in
            task?.cancel()
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
        var task: URLSessionTask?
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                task = call(response: endpoint) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: { [task] in
            task?.cancel()
        }
    }
}
#endif
