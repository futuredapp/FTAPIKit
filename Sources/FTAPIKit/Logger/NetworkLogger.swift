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
        
        // Create log entry with original data
        let logEntry = LogEntry(
            type: .request,
            method: method,
            url: url,
            headers: headers,
            body: bodyString,
            requestId: requestId
        )
        
        // Call analytics callback if provided (with privacy-aware data)
        configuration.analyticsCallback?(logEntry.withPrivacy(configuration.privacy))
        
        // Log to OSLog with proper privacy
        logToOSLog(message: logEntry.buildMessage(), level: .info)
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
        
        // Create log entry with original data
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
        
        // Call analytics callback if provided (with privacy-aware data)
        configuration.analyticsCallback?(logEntry.withPrivacy(configuration.privacy))
        
        // Log to OSLog with proper privacy
        if statusCode >= 400 {
            logToOSLog(message: logEntry.buildMessage(), level: .error)
        } else {
            logToOSLog(message: logEntry.buildMessage(), level: .info)
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
        
        // Create log entry with original data
        let logEntry = LogEntry(
            type: .error,
            method: methodString,
            url: urlString,
            body: dataString,
            error: error,
            requestId: requestId
        )
        
        // Call analytics callback if provided (with privacy-aware data)
        configuration.analyticsCallback?(logEntry.withPrivacy(configuration.privacy))
        
        // Log to OSLog with proper privacy
        logToOSLog(message: logEntry.buildMessage(), level: .error)
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
    
}

#endif
