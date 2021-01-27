import Foundation

public struct URLQuery: ExpressibleByDictionaryLiteral {
    let items: [URLQueryItem]

    init() {
        self.items = []
    }

    public init(items: [(String, String)]) {
        self.items = items.compactMap { key, value in
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryNameValueAllowed),
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryNameValueAllowed) else {
                    return nil
            }
            return URLQueryItem(name: encodedKey, value: encodedValue)
        }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(items: elements)
    }
}
