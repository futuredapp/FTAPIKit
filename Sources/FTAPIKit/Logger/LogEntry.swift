import Foundation

/// Represents a log entry for analytics or custom processing
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct LogEntry {
    public let type: EntryType
    public let headers: [String: String]?
    public let body: Data?
    public let timestamp: Date
    public let duration: TimeInterval?
    public let requestId: String
    
    public init(
        type: EntryType,
        headers: [String: String]? = nil,
        body: Data? = nil,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        requestId: String = UUID().uuidString
    ) {
        self.type = type
        self.headers = headers
        self.body = body
        self.timestamp = timestamp
        self.duration = duration
        self.requestId = requestId
    }
    
    /// Convenience computed properties for accessing associated values
    public var method: String {
        switch type {
        case .request(let method, _), .response(let method, _, _), .error(let method, _, _):
            return method
        }
    }
    
    public var url: String {
        switch type {
        case .request(_, let url), .response(_, let url, _), .error(_, let url, _):
            return url
        }
    }
    
    public var statusCode: Int? {
        switch type {
        case .response(_, _, let statusCode):
            return statusCode
        case .request, .error:
            return nil
        }
    }
    
    public var error: String? {
        switch type {
        case .error(_, _, let error):
            return error
        case .request, .response:
            return nil
        }
    }
    
    
    /// Builds a formatted log message from this LogEntry
    func buildMessage(configuration: LoggerConfiguration) -> String {
        let requestIdPrefix = String(requestId.prefix(8))
        
        switch type {
        case .request(let method, let url):
            var message = "[REQUEST] [\(requestIdPrefix)] \(method) \(url)"
            
            if let headers = headers, !headers.isEmpty {
                message += " Headers: \(headers)"
            }
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += " Body: \(bodyString)"
            }
            
            return message
            
        case .response(let method, let url, let statusCode):
            var message = "[RESPONSE] [\(requestIdPrefix)] \(method) \(url) \(statusCode)"
            
            if let duration = duration {
                message += " (\(String(format: "%.2f", duration * 1000))ms)"
            }
            
            if let headers = headers, !headers.isEmpty {
                message += " Headers: \(headers)"
            }
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += " Body: \(bodyString)"
            }
            
            return message
            
        case .error(let method, let url, let error):
            var message = "[ERROR] [\(requestIdPrefix)] \(method) \(url) ERROR: \(error)"
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += " Data: \(bodyString)"
            }
            
            return message
        }
    }
    
    
}
