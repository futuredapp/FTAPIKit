import Foundation

public struct URLQuery: ExpressibleByDictionaryLiteral {
    public let items: [URLQueryItem]

    init() {
        self.items = []
    }

    public init(items: [URLQueryItem]) {
        self.items = items
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(items: elements.map(URLQueryItem.init))
    }

    private func encode(item: URLQueryItem) -> URLQueryItem {
        let encodedName = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryNameValueAllowed) ?? item.name
        let encodedValue = item.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryNameValueAllowed)
        return URLQueryItem(name: encodedName, value: encodedValue)
    }

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
