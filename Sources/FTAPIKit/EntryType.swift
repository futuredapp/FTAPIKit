import Foundation

/// Represents the type of network entry with associated data.
/// 
/// This enum uses associated values to provide type-safe access to network entry data,
/// eliminating the need for optionals for basic information like method, URL, and status code.
/// 
/// - Note: This enum is used by both ``LogEntry`` and ``AnalyticEntry`` for consistent
/// type-safe data representation across logging and analytics systems.
public enum EntryType {
    /// Represents a network request entry.
    /// - Parameters:
    ///   - method: The HTTP method (e.g., "GET", "POST", "PUT")
    ///   - url: The request URL
    case request(method: String, url: String)
    
    /// Represents a network response entry.
    /// - Parameters:
    ///   - method: The HTTP method that was used
    ///   - url: The request URL that was called
    ///   - statusCode: The HTTP status code returned
    case response(method: String, url: String, statusCode: Int)
    
    /// Represents a network error entry.
    /// - Parameters:
    ///   - method: The HTTP method that was attempted
    ///   - url: The request URL that failed
    ///   - error: The error message describing what went wrong
    case error(method: String, url: String, error: String)
    
    /// The raw string representation for backwards compatibility.
    /// 
    /// This property provides a string representation of the entry type that can be used
    /// for serialization, logging, or analytics tracking.
    public var rawValue: String {
        switch self {
        case .request:
            "request"
        case .response:
            "response"
        case .error:
            "error"
        }
    }
}
