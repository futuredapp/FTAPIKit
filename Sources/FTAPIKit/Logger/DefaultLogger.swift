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
    public let logger: os.Logger
    public let configuration: LoggerConfiguration

    public init(
        subsystem: String = "com.ftapikit.networking",
        category: String = "networking",
        configuration: LoggerConfiguration = LoggerConfiguration()
    ) {
        self.configuration = configuration
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }
    
    
}

#endif
