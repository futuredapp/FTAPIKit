import Foundation

#if os(Linux)
import FoundationNetworking
#endif

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension URLServer {
    
    /// Logs a request before it's sent
    /// - Parameters:
    ///   - request: The URLRequest to log
    ///   - requestId: Unique identifier for this request
    ///   - logger: The network logger instance
    func logRequest(_ request: URLRequest, requestId: String, logger: NetworkLogger) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "UNKNOWN"
        let headers = request.allHTTPHeaderFields
        let body = request.httpBody
        
        logger.logRequest(
            method: method,
            url: url,
            headers: headers,
            body: body,
            requestId: requestId
        )
    }
    
    /// Logs a response after it's received
    /// - Parameters:
    ///   - request: The original URLRequest
    ///   - response: The URLResponse received
    ///   - data: The response data
    ///   - requestId: Unique identifier for this request
    ///   - startTime: The time when the request was started
    ///   - logger: The network logger instance
    func logResponse(
        _ request: URLRequest,
        response: URLResponse?,
        data: Data?,
        requestId: String,
        startTime: Date,
        logger: NetworkLogger
    ) {
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "UNKNOWN"
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let headers = (response as? HTTPURLResponse)?.allHeaderFields as? [String: String]
        let duration = Date().timeIntervalSince(startTime)
        
        logger.logResponse(
            method: method,
            url: url,
            statusCode: statusCode,
            headers: headers,
            body: data,
            duration: duration,
            requestId: requestId
        )
    }
    
    /// Logs an error that occurred during request execution
    /// - Parameters:
    ///   - request: The original URLRequest
    ///   - error: The error that occurred
    ///   - data: The response data (if available)
    ///   - requestId: Unique identifier for this request
    ///   - logger: The network logger instance
    func logError(
        _ request: URLRequest?,
        error: ErrorType,
        data: Data? = nil,
        requestId: String,
        logger: NetworkLogger
    ) {
        let method = request?.httpMethod
        let url = request?.url?.absoluteString
        let errorMessage = String(describing: error)
        
        logger.logError(
            method: method,
            url: url,
            error: errorMessage,
            data: data,
            requestId: requestId
        )
    }
}
