import Foundation

/// `URLQuery` is a helper type, that provides a bridge between Swift and URL queries. It provides a nice, dictionary
/// based Swift API and returns a correct URL query items.
///
/// Notice, that the elements of the dictionary literal are not internally stored as a dictionary. Therefore, arrays are
/// expressible (example follows). However, only type acceptable as `Key` and `Value` is `String`.
///
/// ```
/// let query: URLQuery = [
///     "name" : "John",
///     "child[]" : "Eve",
///     "child[]" : "John jr."
///     "child[]" : "Maggie"
/// ]
/// ```
public struct URLQuery: ExpressibleByDictionaryLiteral {
    /// Query items
    public let items: [URLQueryItem]

    init() {
        self.items = []
    }

    public init(items: [URLQueryItem]) {
        self.items = items
    }

    /// Doctionary literals may not be unique, same keys are allowed and own't be overriden.
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

    /// String of all query items, encoded by percent endocing and divided by `&` delimiter.
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
