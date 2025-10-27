import Foundation
import os.log

#if canImport(os.log)

/// Network logger that uses OSLog with configurable privacy and analytics
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct NetworkLogger {
    private let logger: os.Logger
    private let configuration: LoggerConfiguration
    
    public init(configuration: LoggerConfiguration = LoggerConfiguration()) {
        self.configuration = configuration
        self.logger = os.Logger(subsystem: configuration.subsystem, category: configuration.category)
    }
    
    
    /// Logs a network request
    public func logRequest(
        method: String,
        url: String,
        headers: [String: String]? = nil,
        body: Data? = nil,
        requestId: String = UUID().uuidString
    ) {
        let bodyString = body.flatMap { configuration.dataDecoder($0) }
        
        // Create log entry for analytics (with original data)
        let logEntry = LogEntry(
            type: .request,
            method: method,
            url: url,
            headers: headers,
            body: bodyString,
            requestId: requestId
        )
        
        // Call analytics callback if provided
        configuration.analyticsCallback?(logEntry)
        
        // Log to OSLog with proper privacy
        logToOSLog(
            message: buildRequestMessage(method: method, url: url, headers: headers, body: bodyString, requestId: requestId)
        )
    }
    
    /// Logs a network response
    public func logResponse(
        method: String,
        url: String,
        statusCode: Int,
        headers: [String: String]? = nil,
        body: Data? = nil,
        duration: TimeInterval? = nil,
        requestId: String
    ) {
        let bodyString = body.flatMap { configuration.dataDecoder($0) }
        
        // Create log entry for analytics (with original data)
        let logEntry = LogEntry(
            type: .response,
            method: method,
            url: url,
            headers: headers,
            body: bodyString,
            statusCode: statusCode,
            duration: duration,
            requestId: requestId
        )
        
        // Call analytics callback if provided
        configuration.analyticsCallback?(logEntry)
        
        // Log to OSLog with proper privacy
        let message = buildResponseMessage(
            method: method,
            url: url,
            statusCode: statusCode,
            headers: headers,
            body: bodyString,
            duration: duration,
            requestId: requestId
        )
        
        if statusCode >= 400 {
            logToOSLog(message: message, level: .error)
        } else {
            logToOSLog(message: message, level: .info)
        }
    }
    
    /// Logs a network error
    public func logError(
        method: String?,
        url: String?,
        error: String,
        data: Data? = nil,
        requestId: String = UUID().uuidString
    ) {
        let methodString = method ?? "UNKNOWN"
        let urlString = url ?? "UNKNOWN"
        let dataString = data.flatMap { configuration.dataDecoder($0) }
        
        // Create log entry for analytics (with original data)
        let logEntry = LogEntry(
            type: .error,
            method: methodString,
            url: urlString,
            body: dataString,
            error: error,
            requestId: requestId
        )
        
        // Call analytics callback if provided
        configuration.analyticsCallback?(logEntry)
        
        // Log to OSLog with proper privacy
        let message = buildErrorMessage(method: methodString, url: urlString, error: error, data: dataString, requestId: requestId)
        logToOSLog(message: message, level: .error)
    }
    
    // MARK: - Private Methods
    
    private func logToOSLog(message: String, level: OSLogType = .info) {
        switch configuration.privacy {
        case .none:
            logger.log(level: level, "\(message, privacy: .public)")
        case .auto:
            logger.log(level: level, "\(message, privacy: .auto)")
        case .private:
            logger.log(level: level, "\(message, privacy: .private)")
        case .sensitive:
            logger.log(level: level, "\(message, privacy: .sensitive)")
        }
    }
    
    private func buildRequestMessage(
        method: String,
        url: String,
        headers: [String: String]?,
        body: String?,
        requestId: String
    ) -> String {
        var message = "[REQUEST] [\(String(requestId.prefix(8)))] \(method) \(url)"
        
        if let headers = headers, !headers.isEmpty {
            message += " Headers: \(headers)"
        }
        
        if let body = body {
            message += " Body: \(body)"
        }
        
        return message
    }
    
    private func buildResponseMessage(
        method: String,
        url: String,
        statusCode: Int,
        headers: [String: String]?,
        body: String?,
        duration: TimeInterval?,
        requestId: String
    ) -> String {
        var message = "[RESPONSE] [\(String(requestId.prefix(8)))] \(method) \(url) \(statusCode)"
        
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
    }
    
    private func buildErrorMessage(
        method: String,
        url: String,
        error: String,
        data: String?,
        requestId: String
    ) -> String {
        var message = "[ERROR] [\(String(requestId.prefix(8)))] \(method) \(url) ERROR: \(error)"
        
        if let data = data {
            message += " Data: \(data)"
        }
        
        return message
    }
}

#endif
