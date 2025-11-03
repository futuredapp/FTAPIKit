import Foundation

/// Represents a log entry for logging network activity.
/// 
/// This struct contains all the data needed to log network requests, responses, and errors.
/// It uses ``EntryType`` with associated values to provide type-safe access to basic
/// network information without optionals.
/// 
/// - Note: For analytics tracking, use ``AnalyticEntry`` instead.
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
        case let .request(method, _), let .response(method, _, _), let .error(method, _, _):
            method
        }
    }
    
    var url: String {
        switch type {
        case let .request(_, url), let .response(_, url, _), let .error(_, url, _):
            url
        }
    }
    
    var statusCode: Int? {
        switch type {
        case let .response(_, _, statusCode):
            statusCode
        case .request, .error:
            nil
        }
    }
    
    var error: String? {
        switch type {
        case let .error(_, _, error):
            error
        case .request, .response:
            nil
        }
    }
    
    
    /// Builds a formatted log message from this LogEntry
    func buildMessage(configuration: LoggerConfiguration) -> String {
        let requestIdPrefix = String(requestId.prefix(8))
        let timestampString = formatTimestamp(timestamp)
        
        switch type {
        case let .request(method, url):
            var message = "[REQUEST] [\(requestIdPrefix)]"
            
            // Collect all titles for alignment calculation
            var allTitles = ["Method", "URL", "Timestamp"]
            if let headers, !headers.isEmpty {
                allTitles.append(contentsOf: headers.keys)
            }
            
            let maxTitleLength = allTitles.map { $0.count }.max() ?? 0
            message += format(title: "Method", text: method, maxTitleLength: maxTitleLength)
            message += format(title: "URL", text: url, maxTitleLength: maxTitleLength)
            message += format(title: "Timestamp", text: timestampString, maxTitleLength: maxTitleLength)

            if let headers, !headers.isEmpty {
                message += format(headers: headers, maxTitleLength: maxTitleLength)
            }
            
            if let body, let bodyString = configuration.dataDecoder(body) {
                message += "\n\tBody:\n \(bodyString)"
            }
            
            return message
            
        case let .response(method, url, statusCode):
            var message = "[RESPONSE] [\(requestIdPrefix)]"
            
            // Collect all titles for alignment calculation
            var allTitles = ["Method", "URL", "Status Code", "Timestamp"]
            if duration != nil {
                allTitles.append("Duration")
            }
            if let headers, !headers.isEmpty {
                allTitles.append(contentsOf: headers.keys)
            }
            
            let maxTitleLength = allTitles.map { $0.count }.max() ?? 0
            message += format(title: "Method", text: method, maxTitleLength: maxTitleLength)
            message += format(title: "URL", text: url, maxTitleLength: maxTitleLength)
            message += format(title: "Status Code", text: "\(statusCode)", maxTitleLength: maxTitleLength)
            message += format(title: "Timestamp", text: timestampString, maxTitleLength: maxTitleLength)

            if let duration {
                message += format(title: "Duration", text: "\(String(format: "%.2f", duration * 1000))ms", maxTitleLength: maxTitleLength)
            }
            
            if let headers, !headers.isEmpty {
                message += format(headers: headers, maxTitleLength: maxTitleLength)
            }
            
            if let body, let bodyString = configuration.dataDecoder(body) {
                message += "\nBody:\n \(bodyString)"
            }
            
            return message
            
        case let .error(method, url, error):
            var message = "[ERROR] [\(requestIdPrefix)]"
            
            // Collect all titles for alignment calculation
            var allTitles = ["Method", "URL", "ERROR", "Timestamp"]
            if let headers, !headers.isEmpty {
                allTitles.append(contentsOf: headers.keys)
            }
            
            let maxTitleLength = allTitles.map { $0.count }.max() ?? 0
            message += format(title: "Method", text: method, maxTitleLength: maxTitleLength)
            message += format(title: "URL", text: url, maxTitleLength: maxTitleLength)
            message += format(title: "ERROR", text: error, maxTitleLength: maxTitleLength)
            message += format(title: "Timestamp", text: timestampString, maxTitleLength: maxTitleLength)

            if let body, let bodyString = configuration.dataDecoder(body) {
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
