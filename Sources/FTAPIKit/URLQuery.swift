import Foundation

public struct URLQuery: ExpressibleByDictionaryLiteral {
    let items: [URLQueryItem]

    init() {
        self.items = []
    }

    public init(items: [(String, String)]) {
        self.items = items.map(URLQueryItem.init)
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(items: elements)
    }
}
