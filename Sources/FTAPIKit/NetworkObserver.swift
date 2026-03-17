import Foundation

/// Protocol for observing network request lifecycle events.
///
/// Implement this protocol to add logging, analytics, or request tracking.
///
/// ## Context Lifecycle
/// The `Context` associated type allows passing correlation data (request ID, start time, etc.)
/// through the request lifecycle:
/// 1. `willSendRequest` is called before the request starts and returns a `Context` value
/// 2. `didReceiveResponse` is called when a response is received from the server
/// 3. `didFail` is called additionally if the request processing fails (network, HTTP status, or decoding error)
///
/// - Note: Observers are strongly retained for the duration of a request to ensure lifecycle callbacks
///   are always delivered.
public protocol NetworkObserver: AnyObject, Sendable {
    associatedtype Context: Sendable

    /// Called immediately before a request is sent.
    /// - Parameter request: The URLRequest about to be sent
    /// - Returns: Context to be passed to `didReceiveResponse` and optionally `didFail`
    func willSendRequest(_ request: URLRequest) -> Context

    /// Called when a response is received from the server.
    ///
    /// Only called when the server responds. Not called on network errors (e.g. no connectivity).
    /// Called even if the response indicates an error (4xx, 5xx), before `didFail`.
    /// - Parameters:
    ///   - request: The original request
    ///   - response: The URL response (may be HTTPURLResponse)
    ///   - data: Response body data, if any (nil for download tasks)
    ///   - context: Value returned from `willSendRequest`
    func didReceiveResponse(for request: URLRequest, response: URLResponse?, data: Data?, context: Context)

    /// Called when a request fails with an error.
    ///
    /// Called after `didReceiveResponse` if processing determines the request failed.
    /// - Parameters:
    ///   - request: The original request
    ///   - error: The error that occurred (may be network, HTTP status, or decoding error)
    ///   - context: Value returned from `willSendRequest`
    func didFail(request: URLRequest, error: Error, context: Context)
}
