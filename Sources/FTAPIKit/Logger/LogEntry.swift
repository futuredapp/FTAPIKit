import Foundation

/// Represents a log entry for analytics or custom processing
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct LogEntry {
    public enum EntryType: String {
        case request = "request"
        case response = "response"
        case error = "error"
    }
    
    public let type: EntryType
    public let method: String?
    public let url: String?
    public let headers: [String: String]?
    public let body: Data?
    public let statusCode: Int?
    public let error: String?
    public let timestamp: Date
    public let duration: TimeInterval?
    public let requestId: String
    
    public init(
        type: EntryType,
        method: String? = nil,
        url: String? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        statusCode: Int? = nil,
        error: String? = nil,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        requestId: String = UUID().uuidString
    ) {
        self.type = type
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.statusCode = statusCode
        self.error = error
        self.timestamp = timestamp
        self.duration = duration
        self.requestId = requestId
    }
    
    
    /// Builds a formatted log message from this LogEntry
    func buildMessage(configuration: LoggerConfiguration) -> String {
        let requestIdPrefix = String(requestId.prefix(8))
        
        switch type {
        case .request:
            var message = "[REQUEST] [\(requestIdPrefix)] \(method ?? "UNKNOWN") \(url ?? "UNKNOWN")"
            
            if let headers = headers, !headers.isEmpty {
                message += " Headers: \(headers)"
            }
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += " Body: \(bodyString)"
            }
            
            return message
            
        case .response:
            var message = "[RESPONSE] [\(requestIdPrefix)] \(method ?? "UNKNOWN") \(url ?? "UNKNOWN") \(statusCode ?? 0)"
            
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
            
        case .error:
            var message = "[ERROR] [\(requestIdPrefix)] \(method ?? "UNKNOWN") \(url ?? "UNKNOWN") ERROR: \(error ?? "Unknown error")"
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += " Data: \(bodyString)"
            }
            
            return message
        }
    }
    
    
}
