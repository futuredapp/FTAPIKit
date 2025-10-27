import Foundation
import os.log

#if canImport(os.log)

/// Default logger implementation that uses OSLog with configurable privacy settings.
/// 
/// This is the standard implementation of ``LoggerProtocol`` that uses the native `OSLog`
/// system for logging network activity. It provides automatic privacy masking based on
/// the configured privacy level.
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
/// // Basic usage with default configuration
/// let logger = DefaultLogger()
/// 
/// // Advanced usage with custom configuration
/// let configuration = LoggerConfiguration(
///     subsystem: "com.myapp.networking",
///     category: "api",
///     privacy: .auto
/// )
/// let logger = DefaultLogger(configuration: configuration)
/// 
/// // Use with URLServer
/// let server = APIServer(logger: logger)
/// ```
/// 
/// - Note: This logger automatically masks sensitive data based on the configured
/// privacy level using the native `OSLogPrivacy` system.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct DefaultLogger: LoggerProtocol {
    private let logger: os.Logger
    private let configuration: LoggerConfiguration
    
    public init(configuration: LoggerConfiguration = LoggerConfiguration()) {
        self.configuration = configuration
        self.logger = os.Logger(subsystem: configuration.subsystem, category: configuration.category)
    }
    
    public func log(_ entry: LogEntry) {
        // Log to OSLog with proper privacy
        let level: OSLogType = {
            switch entry.type {
            case .error:
                return .error
            case .response(_, _, let statusCode):
                return statusCode >= 400 ? .error : .info
            case .request:
                return .info
            }
        }()
        logToOSLog(message: entry.buildMessage(configuration: configuration), level: level)
    }
    
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
