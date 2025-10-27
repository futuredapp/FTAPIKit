import Foundation

/// Configuration for analytics functionality
public struct AnalyticsConfiguration {
    public let privacy: AnalyticsPrivacy
    public let sensitiveHeaders: Set<String>
    public let sensitiveUrlQueries: Set<String>
    public let sensitiveBodyParams: Set<String>
    
    public init(
        privacy: AnalyticsPrivacy,
        sensitiveHeaders: Set<String>,
        sensitiveUrlQueries: Set<String>,
        sensitiveBodyParams: Set<String>
    ) {
        self.privacy = privacy
        self.sensitiveHeaders = sensitiveHeaders
        self.sensitiveUrlQueries = sensitiveUrlQueries
        self.sensitiveBodyParams = sensitiveBodyParams
    }
    
    /// Default analytics configuration with sensitive privacy
    public static let `default` = AnalyticsConfiguration(
        privacy: .sensitive,
        sensitiveHeaders: defaultSensitiveHeaders,
        sensitiveUrlQueries: defaultSensitiveUrlQueries,
        sensitiveBodyParams: defaultSensitiveBodyParams
    )
    
    /// Default sensitive headers that should be masked
    public static let defaultSensitiveHeaders: Set<String> = [
        "authorization", "x-api-key", "x-auth-token", "cookie", "set-cookie",
        "x-csrf-token", "x-requested-with", "x-forwarded-for", "x-real-ip"
    ]
    
    /// Default sensitive URL query parameters that should be masked
    public static let defaultSensitiveUrlQueries: Set<String> = [
        "token", "key", "secret", "password", "auth", "access_token", "refresh_token",
        "api_key", "session_id", "csrf_token", "jwt"
    ]
    
    /// Default sensitive body parameters that should be masked
    public static let defaultSensitiveBodyParams: Set<String> = [
        "password", "secret", "token", "key", "auth", "access_token", "refresh_token",
        "api_key", "session_id", "csrf_token", "jwt", "private_key", "client_secret"
    ]
    
    /// Creates a privacy-aware AnalyticEntry by masking sensitive data
    public func maskAnalyticEntry(_ entry: AnalyticEntry) -> AnalyticEntry {
        return AnalyticEntry(
            type: entry.type,
            method: entry.method,
            url: maskUrl(entry.url),
            headers: maskHeaders(entry.headers),
            body: entry.body, // Body masking is handled by dataMasker in LoggerConfiguration
            statusCode: entry.statusCode,
            error: entry.error,
            timestamp: entry.timestamp,
            duration: entry.duration,
            requestId: entry.requestId
        )
    }
    
    // MARK: - Public Masking Methods
    
    public func maskUrl(_ url: String?) -> String? {
        guard let url = url else { return nil }
        
        switch privacy {
        case .none:
            return url
        case .auto:
            // Mask only sensitive query parameters
            return maskSensitiveUrlQueries(url)
        case .private, .sensitive:
            // Mask all query parameters
            if let urlComponents = URLComponents(string: url) {
                var maskedComponents = urlComponents
                maskedComponents.query = nil
                return maskedComponents.url?.absoluteString ?? url
            }
            return url
        }
    }
    
    private func maskSensitiveUrlQueries(_ url: String) -> String {
        guard let urlComponents = URLComponents(string: url),
              let queryItems = urlComponents.queryItems else { return url }
        
        let maskedQueryItems = queryItems.map { item in
            if sensitiveUrlQueries.contains(item.name.lowercased()) {
                return URLQueryItem(name: item.name, value: "***")
            }
            return item
        }
        
        var maskedComponents = urlComponents
        maskedComponents.queryItems = maskedQueryItems
        return maskedComponents.url?.absoluteString ?? url
    }
    
    public func maskHeaders(_ headers: [String: String]?) -> [String: String]? {
        guard let headers = headers else { return nil }
        
        switch privacy {
        case .none:
            return headers
        case .auto:
            return maskSensitiveHeaders(headers)
        case .private, .sensitive:
            return headers.mapValues { _ in "***" }
        }
    }
    
    public func maskBody(_ body: Data?) -> Data? {
        guard let body = body else { return nil }
        
        switch privacy {
        case .none:
            return body
        case .auto:
            return maskSensitiveBodyParams(body) // Return nil if masking fails
        case .private, .sensitive:
            return nil // Always return nil for private/sensitive privacy
        }
    }
    
    private func maskSensitiveHeaders(_ headers: [String: String]) -> [String: String] {
        var maskedHeaders: [String: String] = [:]
        for (key, value) in headers {
            if sensitiveHeaders.contains(key.lowercased()) {
                maskedHeaders[key] = "***"
            } else {
                maskedHeaders[key] = value
            }
        }
        return maskedHeaders
    }
    
    private func maskSensitiveBodyParams(_ body: Data) -> Data? {
        // Try to decode as JSON and mask sensitive parameters
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return nil // If not JSON, return nil
        }
        
        var maskedJson = json
        for key in sensitiveBodyParams {
            if maskedJson[key] != nil {
                maskedJson[key] = "***"
            }
        }
        
        // Convert back to Data
        guard let maskedData = try? JSONSerialization.data(withJSONObject: maskedJson) else {
            return nil // If conversion fails, return nil
        }
        
        return maskedData
    }
}
