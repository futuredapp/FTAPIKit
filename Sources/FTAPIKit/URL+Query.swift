import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import MobileCoreServices
#endif

extension URL {
    mutating func appendQuery(parameters: [URLQueryItem]) {
        self = appendingQuery(parameters: parameters)
    }

    func appendingQuery(parameters: [URLQueryItem]) -> URL {
        guard !parameters.isEmpty else {
            return self
        }
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let oldItems = components?.queryItems ?? []
        components?.queryItems = oldItems + parameters
        return components?.url ?? self
    }
}
