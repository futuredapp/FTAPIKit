import Foundation

public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an ``APIError`` if the request fails or server returns an error,
    ///   or an error from ``RequestConfiguring/configure(_:)`` if configuration fails.
    func call(endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws {
        _ = try await execute(endpoint: endpoint, configuring: configuring)
    }

    /// Performs call to endpoint which returns arbitrary data in the HTTP response, that should not be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an ``APIError`` if the request fails or server returns an error,
    ///   or an error from ``RequestConfiguring/configure(_:)`` if configuration fails.
    /// - Returns: Plain data returned with the HTTP Response
    func call(data endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws -> Data {
        try await execute(endpoint: endpoint, configuring: configuring).data
    }

    /// Performs call to endpoint which returns data that are supposed to be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an ``APIError`` if the request fails or server returns an error.
    ///   Throws a `DecodingError` directly if response decoding fails (decoding errors are not
    ///   routed through ``URLServer/ErrorType``).
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

    /// Downloads a file from the specified endpoint to a temporary location.
    /// - Parameters:
    ///   - endpoint: The endpoint
    ///   - configuring: Optional request configuration to apply before sending
    /// - Throws: Throws an ``APIError`` if the request fails or server returns an error,
    ///   or an error from ``RequestConfiguring/configure(_:)`` if configuration fails.
    /// - Returns: The location of a temporary file where the server's response is stored.
    ///   You must move this file or open it for reading before the async function returns. Otherwise, the file
    ///   is deleted, and the data is lost.
    func download(endpoint: Endpoint, configuring: RequestConfiguring? = nil) async throws -> URL {
        let (urlRequest, observers) = try await prepareObservers(endpoint: endpoint, configuring: configuring)

        let (localURL, response): (URL, URLResponse)
        do {
            (localURL, response) = try await urlSession.download(for: urlRequest)
        } catch {
            observers.forEach { $0.didFail(request: urlRequest, error: error) }
            throw error
        }

        observers.forEach { $0.didReceiveResponse(for: urlRequest, response: response, data: nil) }
        try checkForError(data: nil, response: response, request: urlRequest, observers: observers)

        return localURL
    }
}

// MARK: - Private helpers

private struct ExecuteResult {
    let data: Data
    let request: URLRequest
    let observers: [BoundObserverContext]
}

private extension URLServer {

    /// Core execution method that builds the request, notifies observers, performs the network call,
    /// and handles errors.
    func execute(endpoint: Endpoint, configuring: RequestConfiguring?) async throws -> ExecuteResult {
        let (urlRequest, observers) = try await prepareObservers(endpoint: endpoint, configuring: configuring)

        let file = (endpoint as? UploadEndpoint)?.file

        let (data, response): (Data, URLResponse)
        do {
            if let file {
                (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
            } else {
                (data, response) = try await urlSession.data(for: urlRequest)
            }
        } catch {
            observers.forEach { $0.didFail(request: urlRequest, error: error) }
            throw error
        }

        observers.forEach { $0.didReceiveResponse(for: urlRequest, response: response, data: data) }
        try checkForError(data: data, response: response, request: urlRequest, observers: observers)

        return ExecuteResult(data: data, request: urlRequest, observers: observers)
    }

    /// Builds the URLRequest for the endpoint, applies optional configuration, and creates observer contexts.
    func prepareObservers(
        endpoint: Endpoint,
        configuring: RequestConfiguring?
    ) async throws -> (URLRequest, [BoundObserverContext]) {
        var urlRequest = try await buildRequest(endpoint: endpoint)
        try await configuring?.configure(&urlRequest)
        let observers = networkObservers.map { BoundObserverContext(observer: $0, request: urlRequest) }
        return (urlRequest, observers)
    }

    /// Checks the response for API errors and notifies observers on failure.
    func checkForError(
        data: Data?,
        response: URLResponse,
        request: URLRequest,
        observers: [BoundObserverContext]
    ) throws {
        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            observers.forEach { $0.didFail(request: request, error: error) }
            throw error
        }
    }
}

/// Captures an observer and its context from `willSendRequest`, binding the lifecycle callbacks
/// for a single request. Created at request start and consumed before the call returns.
///
/// Marked `@unchecked Sendable` because the stored closures capture a `Sendable` observer
/// and its `Sendable` context. Instances are created and consumed within a single async call
/// and never shared across task boundaries.
private final class BoundObserverContext: @unchecked Sendable {
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
