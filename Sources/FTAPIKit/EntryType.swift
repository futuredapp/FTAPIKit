import Foundation

/// Represents the type of network entry with associated data
public enum EntryType {
    case request(method: String, url: String)
    case response(method: String, url: String, statusCode: Int)
    case error(method: String, url: String, error: String)
    
    /// The raw string representation for backwards compatibility
    public var rawValue: String {
        switch self {
        case .request:
            return "request"
        case .response:
            return "response"
        case .error:
            return "error"
        }
    }
    
}
