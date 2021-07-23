import Foundation

extension URL {
    mutating func appendQuery(_ query: URLQuery) {
        self = appendingQuery(query)
    }

    func appendingQuery(_ query: URLQuery) -> URL {
        guard let query = query.percentEncoded else {
            return self
        }
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let queries = [
            components?.percentEncodedQuery,
            query
        ]
        components?.percentEncodedQuery = queries.compactMap { $0 }.joined(separator: "&")
        return components?.url ?? self
    }
}
