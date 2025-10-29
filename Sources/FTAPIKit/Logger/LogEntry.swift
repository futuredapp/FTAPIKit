import Foundation

/// Represents a log entry for logging network activity.
/// 
/// This struct contains all the data needed to log network requests, responses, and errors.
/// It uses ``EntryType`` with associated values to provide type-safe access to basic
/// network information without optionals.
/// 
/// ## Requirements
/// 
/// - iOS 14.0+
/// - macOS 11.0+
/// - tvOS 14.0+
/// - watchOS 7.0+
/// 
/// ## Usage
/// 
/// ```swift
/// let logEntry = LogEntry(
///     type: .request(method: "GET", url: "https://api.example.com/users"),
///     headers: ["Authorization": "Bearer token123"],
///     body: "{\"username\": \"user\"}".data(using: .utf8)!,
///     requestId: "abc12345"
/// )
/// 
/// // Access data through computed properties
/// print(logEntry.method) // "GET"
/// print(logEntry.url)    // "https://api.example.com/users"
/// print(logEntry.statusCode) // nil (for request entries)
/// ```
/// 
/// - Note: This struct is used by ``LoggerProtocol`` implementations for logging
/// network activity. For analytics tracking, use ``AnalyticEntry`` instead.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct LogEntry {
    let type: EntryType
    let headers: [String: String]?
    let body: Data?
    let timestamp: Date
    let duration: TimeInterval?
    let requestId: String
    
    init(
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
    var method: String {
        switch type {
        case .request(let method, _), .response(let method, _, _), .error(let method, _, _):
            return method
        }
    }
    
    var url: String {
        switch type {
        case .request(_, let url), .response(_, let url, _), .error(_, let url, _):
            return url
        }
    }
    
    var statusCode: Int? {
        switch type {
        case .response(_, _, let statusCode):
            return statusCode
        case .request, .error:
            return nil
        }
    }
    
    var error: String? {
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
        let timestampString = formatTimestamp(timestamp)
        
        switch type {
        case .request(let method, let url):
            var message = "[REQUEST] [\(requestIdPrefix)]"
            
            // Collect all titles for alignment calculation
            var allTitles = ["Method", "URL", "Timestamp"]
            if let headers = headers, !headers.isEmpty {
                allTitles.append(contentsOf: headers.keys)
            }
            
            let maxTitleLength = allTitles.map { $0.count }.max() ?? 0
            message += format(title: "Method", text: method, maxTitleLength: maxTitleLength)
            message += format(title: "URL", text: url, maxTitleLength: maxTitleLength)
            message += format(title: "Timestamp", text: timestampString, maxTitleLength: maxTitleLength)

            if let headers = headers, !headers.isEmpty {
                message += format(headers: headers, maxTitleLength: maxTitleLength)
            }
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += "\n\tBody:\n \(bodyString)"
            }
            
            return message
            
        case .response(let method, let url, let statusCode):
            var message = "[RESPONSE] [\(requestIdPrefix)]"
            
            // Collect all titles for alignment calculation
            var allTitles = ["Method", "URL", "Status Code", "Timestamp"]
            if duration != nil {
                allTitles.append("Duration")
            }
            if let headers = headers, !headers.isEmpty {
                allTitles.append(contentsOf: headers.keys)
            }
            
            let maxTitleLength = allTitles.map { $0.count }.max() ?? 0
            message += format(title: "Method", text: method, maxTitleLength: maxTitleLength)
            message += format(title: "URL", text: url, maxTitleLength: maxTitleLength)
            message += format(title: "Status Code", text: "\(statusCode)", maxTitleLength: maxTitleLength)
            message += format(title: "Timestamp", text: timestampString, maxTitleLength: maxTitleLength)

            if let duration = duration {
                message += format(title: "Duration", text: "\(String(format: "%.2f", duration * 1000))ms", maxTitleLength: maxTitleLength)
            }
            
            if let headers = headers, !headers.isEmpty {
                message += format(headers: headers, maxTitleLength: maxTitleLength)
            }
            
            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += "\nBody:\n \(bodyString)"
            }
            
            return message
            
        case .error(let method, let url, let error):
            var message = "[ERROR] [\(requestIdPrefix)]"
            
            // Collect all titles for alignment calculation
            var allTitles = ["Method", "URL", "ERROR", "Timestamp"]
            if let headers = headers, !headers.isEmpty {
                allTitles.append(contentsOf: headers.keys)
            }
            
            let maxTitleLength = allTitles.map { $0.count }.max() ?? 0
            message += format(title: "Method", text: method, maxTitleLength: maxTitleLength)
            message += format(title: "URL", text: url, maxTitleLength: maxTitleLength)
            message += format(title: "ERROR", text: error, maxTitleLength: maxTitleLength)
            message += format(title: "Timestamp", text: timestampString, maxTitleLength: maxTitleLength)

            if let body = body, let bodyString = configuration.dataDecoder(body) {
                message += "\nData: \(bodyString)"
            }
            
            return message
        }
    }

    private func format(headers: [String: String], maxTitleLength: Int) -> String {
        guard !headers.isEmpty else {
            return ""
        }

        var message = "\nHeaders:"
        // Sort headers by key to ensure consistent ordering
        let sortedHeaders = headers.sorted { $0.key < $1.key }
        for (key, value) in sortedHeaders {
            message += format(title: key, text: value, maxTitleLength: maxTitleLength)
        }
        return message
    }

    private func format(title: String, text: String, maxTitleLength: Int) -> String {
        let padding = String(repeating: " ", count: max(1, maxTitleLength - title.count))
        return "\n\t\(title)\(padding)\(text)"
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
