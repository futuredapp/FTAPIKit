import Foundation

public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an APIError if the request fails or server returns an error
    func call(endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws {
        _ = try await execute(endpoint: endpoint, configuring: configuring)
    }

    /// Performs call to endpoint which returns arbitrary data in the HTTP response, that should not be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: Plain data returned with the HTTP Response
    func call(data endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws -> Data {
        try await execute(endpoint: endpoint, configuring: configuring).data
    }

    /// Performs call to endpoint which returns data that are supposed to be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an APIError if the request fails, server returns an error, or decoding fails
    /// - Returns: Instance of the required type
    func call<EP: ResponseEndpoint>(response endpoint: EP, configuring: RequestConfiguring? = nil) async throws -> EP.Response {
        let result = try await execute(endpoint: endpoint, configuring: configuring)
        do {
            return try decoding.decode(data: result.data)
        } catch {
            result.observers.forEach { $0.didFail(request: result.request, error: error) }
            throw error
        }
    }
}

// MARK: - Private helpers

private struct ExecuteResult {
    let data: Data
    let request: URLRequest
    let observers: [AnyObserverToken]
}

private extension URLServer {

    /// Core execution method that builds the request, notifies observers, performs the network call,
    /// and handles errors.
    func execute(endpoint: Endpoint, configuring: RequestConfiguring?) async throws -> ExecuteResult {
        var urlRequest = try await buildRequest(endpoint: endpoint)
        try await configuring?.configure(&urlRequest)

        let observers = networkObservers.map { AnyObserverToken(observer: $0, request: urlRequest) }

        let file = (endpoint as? UploadEndpoint)?.file

        let (data, response): (Data, URLResponse)
        do {
            if let file {
                (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
            } else {
                (data, response) = try await urlSession.data(for: urlRequest)
            }
        } catch {
            observers.forEach { $0.didReceiveResponse(for: urlRequest, response: nil, data: nil) }
            observers.forEach { $0.didFail(request: urlRequest, error: error) }
            throw error
        }

        observers.forEach { $0.didReceiveResponse(for: urlRequest, response: response, data: data) }

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            observers.forEach { $0.didFail(request: urlRequest, error: error) }
            throw error
        }

        return ExecuteResult(data: data, request: urlRequest, observers: observers)
    }
}

/// Type-erasing wrapper that captures an observer and its context from `willSendRequest`.
final class AnyObserverToken: @unchecked Sendable {
    private let _didReceiveResponse: (URLRequest, URLResponse?, Data?) -> Void
    private let _didFail: (URLRequest, Error) -> Void

    init<O: NetworkObserver>(observer: O, request: URLRequest) {
        let context = observer.willSendRequest(request)
        _didReceiveResponse = { req, resp, data in
            observer.didReceiveResponse(for: req, response: resp, data: data, context: context)
        }
        _didFail = { req, error in
            observer.didFail(request: req, error: error, context: context)
        }
    }

    func didReceiveResponse(for request: URLRequest, response: URLResponse?, data: Data?) {
        _didReceiveResponse(request, response, data)
    }

    func didFail(request: URLRequest, error: Error) {
        _didFail(request, error)
    }
}
