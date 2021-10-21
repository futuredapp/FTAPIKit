import Foundation

/// ``URLQuery`` is a helper type, that provides a bridge between Swift and URL queries. It provides a nice, dictionary
/// based Swift API and returns a correct URL query items.
///
/// - Note: The elements of the dictionary literal accept duplicate keys. Therefore, arrays and nested structure are
/// expressible (example follows). However, only type acceptable as `Key` and `Value` is `String`.
///
/// ```swift
/// let query: URLQuery = [
///     "name": "John",
///     "child[]": "Eve",
///     "child[]": "John jr.",
///     "child[]": "Maggie"
/// ]
/// ```
public struct URLQuery: ExpressibleByDictionaryLiteral {
    /// Array of URL query items.
    public let items: [URLQueryItem]

    init() {
        self.items = []
    }

    /// Creates a structure representing URL query using array of unencoded URL query items.
    /// - Parameter items: Array of unencoded URL query items.
    public init(items: [URLQueryItem]) {
        self.items = items
    }

    /// Dictionary literals may not be unique, same keys are allowed and can't be overridden.
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(items: elements.map(URLQueryItem.init))
    }

    /// Returns the query item, which is percent encoded version of provided item. If an item is already percent
    /// encoded, it **will** be encoded again.
    private func encode(item: URLQueryItem) -> URLQueryItem {
        let encodedName = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryNameValueAllowed) ?? item.name
        let encodedValue = item.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryNameValueAllowed)
        return URLQueryItem(name: encodedName, value: encodedValue)
    }

    /// String of all query items, encoded by percent encoding and divided by `&` delimiter.
    public var percentEncoded: String? {
        guard !items.isEmpty else {
            return nil
        }
        return items.lazy
            .map(encode)
            .map { item in "\(item.name)=\(item.value ?? String())" }
            .joined(separator: "&")
    }
}
