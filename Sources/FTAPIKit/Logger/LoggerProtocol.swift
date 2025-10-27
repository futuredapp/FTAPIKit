import Foundation

#if canImport(os.log)
import os.log

/// Protocol for logging functionality
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol LoggerProtocol {
    /// Logs a log entry
    func log(_ entry: LogEntry)
}

#endif
