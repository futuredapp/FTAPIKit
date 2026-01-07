import Foundation

#if os(Linux)
import FoundationNetworking
#endif

/// Protocol for observing network request lifecycle events.
///
/// Implement this protocol to add logging, analytics, or request tracking.
/// The `context` parameter allows passing correlation data (request ID, start time, etc.)
/// between `willSendRequest` and the completion callbacks.
public protocol NetworkObserver: AnyObject, Sendable {
    associatedtype Context: Sendable

    /// Called immediately before a request is sent.
    /// - Parameter request: The URLRequest about to be sent
    /// - Returns: Context to be passed to `didReceiveResponse` or `didFail`
    func willSendRequest(_ request: URLRequest) -> Context

    /// Called when a response is received.
    /// - Parameters:
    ///   - request: The original request
    ///   - response: The URL response (may be HTTPURLResponse)
    ///   - data: Response body data, if any (nil for download tasks)
    ///   - context: Value returned from `willSendRequest`
    func didReceiveResponse(for request: URLRequest, response: URLResponse?, data: Data?, context: Context)

    /// Called when a request fails with an error.
    /// - Parameters:
    ///   - request: The original request
    ///   - error: The error that occurred
    ///   - context: Value returned from `willSendRequest`
    func didFail(request: URLRequest, error: Error, context: Context)
}
