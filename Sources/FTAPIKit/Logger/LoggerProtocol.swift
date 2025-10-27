import Foundation

#if canImport(os.log)
import os.log

/// Protocol for logging functionality.
/// 
/// This protocol defines the interface for logging network requests, responses, and errors.
/// It provides a simple, unified way to log network activity with type-safe data.
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
/// struct CustomLogger: LoggerProtocol {
///     func log(_ entry: LogEntry) {
///         // Custom logging implementation
///         print("\(entry.type.rawValue): \(entry.method) \(entry.url)")
///     }
/// }
/// 
/// let logger = CustomLogger()
/// logger.log(LogEntry(type: .request(method: "GET", url: "https://api.example.com")))
/// ```
/// 
/// - Note: The default implementation ``DefaultLogger`` uses the native `OSLog` system
/// with automatic privacy masking based on the configured privacy level.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol LoggerProtocol {
    /// Logs a log entry.
    /// 
    /// This method is called automatically by ``URLServer`` implementations
    /// for all network requests, responses, and errors.
    /// 
    /// - Parameter entry: The log entry containing network activity data
    func log(_ entry: LogEntry)
}

#endif
