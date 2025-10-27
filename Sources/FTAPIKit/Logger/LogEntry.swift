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
    public let body: String?
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
        body: String? = nil,
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
    
    /// Creates a privacy-aware LogEntry by masking sensitive data from an existing LogEntry
    func withPrivacy(_ privacy: LogPrivacy) -> LogEntry {
        return LogEntry(
            type: self.type,
            method: self.method,
            url: Self.maskUrl(self.url, privacy: privacy),
            headers: Self.maskHeaders(self.headers, privacy: privacy),
            body: Self.maskBody(self.body, privacy: privacy),
            statusCode: self.statusCode,
            error: self.error,
            timestamp: self.timestamp,
            duration: self.duration,
            requestId: self.requestId
        )
    }
    
    /// Builds a formatted log message from this LogEntry
    func buildMessage() -> String {
        let requestIdPrefix = String(requestId.prefix(8))
        
        switch type {
        case .request:
            var message = "[REQUEST] [\(requestIdPrefix)] \(method ?? "UNKNOWN") \(url ?? "UNKNOWN")"
            
            if let headers = headers, !headers.isEmpty {
                message += " Headers: \(headers)"
            }
            
            if let body = body {
                message += " Body: \(body)"
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
            
            if let body = body {
                message += " Body: \(body)"
            }
            
            return message
            
        case .error:
            var message = "[ERROR] [\(requestIdPrefix)] \(method ?? "UNKNOWN") \(url ?? "UNKNOWN") ERROR: \(error ?? "Unknown error")"
            
            if let body = body {
                message += " Data: \(body)"
            }
            
            return message
        }
    }
    
    // MARK: - Private Masking Methods
    
    private static func maskUrl(_ url: String?, privacy: LogPrivacy) -> String? {
        guard let url = url else { return nil }
        
        switch privacy {
        case .none, .auto:
            return url
        case .private, .sensitive:
            // Mask query parameters and sensitive parts
            if let urlComponents = URLComponents(string: url) {
                var maskedComponents = urlComponents
                maskedComponents.query = nil
                return maskedComponents.url?.absoluteString ?? url
            }
            return url
        }
    }
    
    private static func maskHeaders(_ headers: [String: String]?, privacy: LogPrivacy) -> [String: String]? {
        guard let headers = headers else { return nil }
        
        switch privacy {
        case .none:
            return headers
        case .auto:
            return maskSensitiveHeaders(headers)
        case .private, .sensitive:
            return headers.mapValues { _ in "***" }
        }
    }
    
    private static func maskBody(_ body: String?, privacy: LogPrivacy) -> String? {
        guard let body = body else { return nil }
        
        switch privacy {
        case .none:
            return body
        case .auto:
            return maskSensitiveBody(body)
        case .private, .sensitive:
            return "***"
        }
    }
    
    private static func maskSensitiveHeaders(_ headers: [String: String]) -> [String: String] {
        let sensitiveHeaders: Set<String> = [
            "authorization", "x-api-key", "x-auth-token", "cookie", "set-cookie",
            "x-csrf-token", "x-requested-with", "x-forwarded-for", "x-real-ip"
        ]
        
        return headers.mapValues { value in
            for sensitiveHeader in sensitiveHeaders {
                if value.lowercased().contains(sensitiveHeader) {
                    return "***"
                }
            }
            return value
        }
    }
    
    private static func maskSensitiveBody(_ body: String) -> String {
        let sensitiveFields: Set<String> = [
            "password", "pass", "pwd", "token", "key", "secret", "auth",
            "access_token", "refresh_token", "api_key", "session_id",
            "credit_card", "card_number", "cvv", "ssn", "social_security"
        ]
        
        var maskedBody = body
        for field in sensitiveFields {
            let pattern = "\"\(field)\"\\s*:\\s*\"[^\"]*\""
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: maskedBody.utf16.count)
            maskedBody = regex?.stringByReplacingMatches(
                in: maskedBody,
                options: [],
                range: range,
                withTemplate: "\"\(field)\":\"***\""
            ) ?? maskedBody
        }
        return maskedBody
    }
}
