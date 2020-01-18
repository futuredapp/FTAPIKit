import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import MobileCoreServices
#endif

extension URL {
    mutating func appendQuery(parameters: [String: String]) {
        self = appendingQuery(parameters: parameters)
    }

    func appendingQuery(parameters: [String: String]) -> URL {
        guard !parameters.isEmpty else {
            return self
        }
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let oldItems = components?.queryItems ?? []
        components?.queryItems = oldItems + parameters.map(URLQueryItem.init)
        return components?.url ?? self
    }

    var mimeType: String {
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(), let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        return "application/octet-stream"
    }
}
