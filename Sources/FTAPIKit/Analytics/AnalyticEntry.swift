import Foundation

/// Data structure for analytics tracking
public struct AnalyticEntry {
    public enum EntryType: String {
        case request = "request"
        case response = "response"
        case error = "error"
    }

    public let type: EntryType
    public let method: String?
    public let url: String?
    public let headers: [String: String]?
    public let body: Data?
    public let statusCode: Int?
    public let error: String?
    public let timestamp: Date
    public let duration: TimeInterval?
    public let requestId: String

    public init(
        type: EntryType,
        method: String? = nil,
        url: String? = nil,
        headers: [String: String]? = nil,
        body: Data? = nil,
        statusCode: Int? = nil,
        error: String? = nil,
        timestamp: Date = Date(),
        duration: TimeInterval? = nil,
        requestId: String = UUID().uuidString
    ) {
        self.type = type
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.statusCode = statusCode
        self.error = error
        self.timestamp = timestamp
        self.duration = duration
        self.requestId = requestId
    }
}
