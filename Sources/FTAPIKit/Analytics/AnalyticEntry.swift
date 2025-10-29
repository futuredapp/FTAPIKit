import Foundation

/// Data structure for analytics tracking.
/// 
/// This struct contains network activity data that has been privacy-masked based on
/// the configured ``AnalyticsConfiguration``. It uses ``EntryType`` with associated values
/// to provide type-safe access to basic network information without optionals.
/// 
/// - Note: This struct is used by ``AnalyticsProtocol`` implementations for tracking
/// network activity. For logging purposes, use ``LogEntry`` instead.
public struct AnalyticEntry {
    public let type: EntryType
    public let headers: [String: String]?
    public let body: Data?
    public let timestamp: Date
    public let duration: TimeInterval?
    public let requestId: String

    public init(
        type: EntryType,
        headers: [String: String]? = nil,
        body: Data? = nil,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        requestId: String = UUID().uuidString,
        configuration: AnalyticsConfiguration = AnalyticsConfiguration.default
    ) {
        // Create masked type with masked URL
        let maskedType: EntryType
        switch type {
        case .request(let method, let url):
            maskedType = .request(method: method, url: configuration.maskUrl(url) ?? url)
        case .response(let method, let url, let statusCode):
            maskedType = .response(method: method, url: configuration.maskUrl(url) ?? url, statusCode: statusCode)
        case .error(let method, let url, let error):
            maskedType = .error(method: method, url: configuration.maskUrl(url) ?? url, error: error)
        }
        
        self.type = maskedType
        self.headers = configuration.maskHeaders(headers)
        self.body = configuration.maskBody(body)
        self.timestamp = timestamp
        self.duration = duration
        self.requestId = requestId
    }
    
    /// Convenience computed properties for accessing associated values
    public var method: String {
        switch type {
        case .request(let method, _), .response(let method, _, _), .error(let method, _, _):
            return method
        }
    }
    
    public var url: String {
        switch type {
        case .request(_, let url), .response(_, let url, _), .error(_, let url, _):
            return url
        }
    }
    
    public var statusCode: Int? {
        switch type {
        case .response(_, _, let statusCode):
            return statusCode
        case .request, .error:
            return nil
        }
    }
    
    public var error: String? {
        switch type {
        case .error(_, _, let error):
            return error
        case .request, .response:
            return nil
        }
    }
}
