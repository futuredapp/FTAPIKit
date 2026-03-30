import Foundation

/// Shared response model for httpbin.org endpoints that return headers.
struct HTTPBinHeadersResponse: Decodable, Sendable {
    let headers: [String: String]
}
