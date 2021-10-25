import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public extension URLServer {
    func buildStandardRequest(endpoint: Endpoint) throws -> URLRequest {
        try URLRequestBuilder(server: self, endpoint: endpoint).build()
    }
}

/// Use this structure to translate an instance of ``Endpoint`` to a valid ``URLRequest``. This type is part
/// of the standard implementation.
struct URLRequestBuilder<S: URLServer> {
    let server: S
    let endpoint: Endpoint

    init(server: S, endpoint: Endpoint) {
        self.server = server
        self.endpoint = endpoint
    }

    /// Creates an instance of `URLRequest` corresponding to provided endpoint executed on provided server.
    /// It is safe to execute this method multiple times per instance lifetime.
    /// - Returns: A valid `URLRequest`.
    func build() throws -> URLRequest {
        let url = server.baseUri
            .appendingPathComponent(endpoint.path)
            .appendingQuery(endpoint.query)
        var request = URLRequest(url: url)

        request.httpMethod = endpoint.method.description
        request.allHTTPHeaderFields = endpoint.headers
        try buildBody(to: &request)
        return request
    }

    private func buildBody(to request: inout URLRequest) throws {
        switch endpoint {
        case let endpoint as DataEndpoint:
            request.httpBody = endpoint.body
        case let endpoint as EncodableEndpoint:
            let requestEncoding = server.encoding as? URLRequestEncoding
            try requestEncoding?.configure(request: &request)
            request.httpBody = try endpoint.body(encoding: server.encoding)
        case let endpoint as URLEncodedEndpoint:
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = endpoint.body.percentEncoded?.data(using: .ascii)
        #if !os(Linux)
        case let endpoint as MultipartEndpoint:
            let formData = MultipartFormData(parts: endpoint.parts)
            request.httpBodyStream = try formData.inputStream()
            request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
            if let contentLength = formData.contentLength {
                request.setValue(contentLength.description, forHTTPHeaderField: "Content-Length")
            }
        #endif
        default:
            break
        }
    }
}
