import Foundation
#if os(Linux)
import FoundationNetworking
#endif

/// Type-erased callbacks for observer lifecycle notifications.
/// Captures the concrete Context type internally via closures.
private struct ObserverCallbacks: Sendable {
    let didReceiveResponse: @Sendable (URLResponse?, Data?) -> Void
    let didFail: @Sendable (Error) -> Void
}

/// Creates type-erased callbacks for an observer by capturing its concrete Context type.
private func makeObserverCallbacks<O: NetworkObserver>(
    for observer: O,
    request: URLRequest
) -> ObserverCallbacks {
    let context = observer.willSendRequest(request)
    return ObserverCallbacks(
        didReceiveResponse: { response, data in
            observer.didReceiveResponse(for: request, response: response, data: data, context: context)
        },
        didFail: { error in
            observer.didFail(request: request, error: error, context: context)
        }
    )
}

private extension URLServer {
    /// Notifies all observers that a request will be sent and returns callbacks for completion.
    func notifyObserversWillSend(_ request: URLRequest) -> [ObserverCallbacks] {
        networkObservers.map { makeObserverCallbacks(for: $0, request: request) }
    }

    /// Notifies all observers that a response was received.
    func notifyObserversDidReceive(
        _ callbacks: [ObserverCallbacks],
        response: URLResponse?,
        data: Data?
    ) {
        for callback in callbacks {
            callback.didReceiveResponse(response, data)
        }
    }

    /// Notifies all observers that a request failed.
    func notifyObserversDidFail(_ callbacks: [ObserverCallbacks], error: Error) {
        for callback in callbacks {
            callback.didFail(error)
        }
    }
}

public extension URLServer {

    /// Performs call to endpoint which does not return any data in the HTTP response.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: Void on success
    func call(endpoint: Endpoint) async throws {
        let urlRequest = try await buildRequest(endpoint: endpoint)
        let callbacks = notifyObserversWillSend(urlRequest)

        #if !os(Linux)
        let file = (endpoint as? UploadEndpoint)?.file
        #else
        let file: URL? = nil
        #endif

        let (data, response): (Data, URLResponse)
        do {
            if let file = file {
                (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
            } else {
                (data, response) = try await urlSession.data(for: urlRequest)
            }
        } catch {
            notifyObserversDidReceive(callbacks, response: nil, data: nil)
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }

        notifyObserversDidReceive(callbacks, response: response, data: data)

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }
    }

    /// Performs call to endpoint which returns arbitrary data in the HTTP response, that should not be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails or server returns an error
    /// - Returns: Plain data returned with the HTTP Response
    func call(data endpoint: Endpoint) async throws -> Data {
        let urlRequest = try await buildRequest(endpoint: endpoint)
        let callbacks = notifyObserversWillSend(urlRequest)

        #if !os(Linux)
        let file = (endpoint as? UploadEndpoint)?.file
        #else
        let file: URL? = nil
        #endif

        let (data, response): (Data, URLResponse)
        do {
            if let file = file {
                (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
            } else {
                (data, response) = try await urlSession.data(for: urlRequest)
            }
        } catch {
            notifyObserversDidReceive(callbacks, response: nil, data: nil)
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }

        notifyObserversDidReceive(callbacks, response: response, data: data)

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }

        return data
    }

    /// Performs call to endpoint which returns data that are supposed to be parsed by the decoder.
    /// - Parameters:
    ///   - endpoint: The endpoint
    /// - Throws: Throws an APIError if the request fails, server returns an error, or decoding fails
    /// - Returns: Instance of the required type
    func call<EP: ResponseEndpoint>(response endpoint: EP) async throws -> EP.Response {
        let urlRequest = try await buildRequest(endpoint: endpoint)
        let callbacks = notifyObserversWillSend(urlRequest)

        #if !os(Linux)
        let file = (endpoint as? UploadEndpoint)?.file
        #else
        let file: URL? = nil
        #endif

        let (data, response): (Data, URLResponse)
        do {
            if let file = file {
                (data, response) = try await urlSession.upload(for: urlRequest, fromFile: file)
            } else {
                (data, response) = try await urlSession.data(for: urlRequest)
            }
        } catch {
            notifyObserversDidReceive(callbacks, response: nil, data: nil)
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }

        notifyObserversDidReceive(callbacks, response: response, data: data)

        if let error = ErrorType(data: data, response: response, error: nil, decoding: decoding) {
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }

        do {
            return try decoding.decode(data: data)
        } catch {
            notifyObserversDidFail(callbacks, error: error)
            throw error
        }
    }
}
