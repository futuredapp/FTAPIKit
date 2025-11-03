import Foundation

/// Configuration for analytics functionality.
///
/// This struct defines the privacy level and exceptions for masking sensitive data
/// in analytics. It allows you to specify which headers, URL query parameters,
/// and body parameters should not be masked.
public struct AnalyticsConfiguration {
    private let privacy: AnalyticsPrivacy
    private let unmaskedHeaders: Set<String>
    private let unmaskedUrlQueries: Set<String>
    private let unmaskedBodyParams: Set<String>

    /// Initializes a new analytics configuration.
    ///
    /// - Parameters:
    ///   - privacy: The privacy level for data masking.
    ///   - unmaskedHeaders: A set of header keys that should not be masked.
    ///   - unmaskedUrlQueries: A set of URL query parameter keys that should not be masked.
    ///   - unmaskedBodyParams: A set of body parameter keys that should not be masked.
    public init(
        privacy: AnalyticsPrivacy,
        unmaskedHeaders: Set<String> = [],
        unmaskedUrlQueries: Set<String> = [],
        unmaskedBodyParams: Set<String> = []
    ) {
        self.privacy = privacy
        self.unmaskedHeaders = unmaskedHeaders
        self.unmaskedUrlQueries = unmaskedUrlQueries
        self.unmaskedBodyParams = unmaskedBodyParams
    }

    /// Default analytics configuration with sensitive privacy
    public static let `default` = AnalyticsConfiguration(privacy: .sensitive)


    // MARK: - Public Masking Methods

    public func maskUrl(_ url: String?) -> String? {
        guard let url = url else { return nil }

        switch privacy {
        case .none:
            return url
        case .private:
            return maskPrivateUrlQueries(url)
        case .sensitive:
            return maskSensitiveUrlQueries(url)
        }
    }

    private func maskPrivateUrlQueries(_ url: String) -> String {
        guard let urlComponents = URLComponents(string: url),
              let queryItems = urlComponents.queryItems else { return url }

        let maskedQueryItems = queryItems.map { item -> URLQueryItem in
            if unmaskedUrlQueries.contains(item.name.lowercased()) {
                return item
            }
            return URLQueryItem(name: item.name, value: "***")
        }

        var maskedComponents = urlComponents
        maskedComponents.queryItems = maskedQueryItems
        return maskedComponents.url?.absoluteString ?? url
    }

    private func maskSensitiveUrlQueries(_ url: String) -> String {
        guard let urlComponents = URLComponents(string: url) else { return url }

        var maskedComponents = urlComponents
        maskedComponents.query = nil
        
        return maskedComponents.url?.absoluteString ?? url
    }

    public func maskHeaders(_ headers: [String: String]?) -> [String: String]? {
        guard let headers = headers else { return nil }

        switch privacy {
        case .none:
            return headers
        case .private:
            var maskedHeaders: [String: String] = [:]
            for (key, value) in headers {
                if unmaskedHeaders.contains(key.lowercased()) {
                    maskedHeaders[key] = value
                } else {
                    maskedHeaders[key] = "***"
                }
            }
            return maskedHeaders
        case .sensitive:
            return headers.mapValues { _ in "***" }
        }
    }

    public func maskBody(_ body: Data?) -> Data? {
        guard let body = body else { return nil }

        switch privacy {
        case .none:
            return body
        case .private:
            return maskPrivateBodyParams(body)
        case .sensitive:
            return nil
        }
    }

    private func maskPrivateBodyParams(_ body: Data) -> Data? {
        guard let json = try? JSONSerialization.jsonObject(with: body) else {
            return "***".data(using: .utf8)
        }

        let maskedJson = recursivelyMask(json)

        return try? JSONSerialization.data(withJSONObject: maskedJson)
    }

    private func recursivelyMask(_ data: Any) -> Any {
        if let dictionary = data as? [String: Any] {
            var newDict: [String: Any] = [:]
            for (key, value) in dictionary {
                if unmaskedBodyParams.contains(key.lowercased()) {
                    newDict[key] = value
                } else {
                    newDict[key] = recursivelyMask(value)
                }
            }
            return newDict
        } else if let array = data as? [Any] {
            return array.map { recursivelyMask($0) }
        } else {
            return "***"
        }
    }
}